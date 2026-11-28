<?php

namespace App\Services;

use App\Models\AffiliationCode;
use App\Models\AffiliationReferral;
use App\Models\AffiliationSetting;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Modules\StoreFront\VendorPanel\Entities\Order;
use Modules\StoreFront\VendorPanel\Entities\Wallet;
use Modules\StoreFront\VendorPanel\Entities\WalletTransaction;
use Modules\StoreFront\VendorPanel\Http\Services\WalletService;

class AffiliationService
{
    public function getSettings(): AffiliationSetting
    {
        $settings = AffiliationSetting::first();
        if (!$settings) {
            $settings = AffiliationSetting::create([
                'issuer_percentage' => 10.00,
                'receiver_percentage' => 10.00,
            ]);
        }
        return $settings;
    }

    public function getOrCreateCodeForUser(int $userId): AffiliationCode
    {
        $existing = AffiliationCode::where('user_id', $userId)->first();
        if ($existing) {
            return $existing;
        }

        do {
            $code = 'AMI-' . Str::upper(Str::random(6));
        } while (AffiliationCode::where('code', $code)->exists());

        return AffiliationCode::create([
            'user_id' => $userId,
            'code' => $code,
            'is_active' => true,
        ]);
    }

    public function getUserDashboard(int $userId): array
    {
        $settings = $this->getSettings();
        $affCode = $this->getOrCreateCodeForUser($userId);

        $referrals = AffiliationReferral::with(['receiver:id,name,email', 'order:id,order_code,order_status_id,yalidine_parcel_status'])
            ->where('issuer_user_id', $userId)
            ->orderByDesc('id')
            ->get()
            ->map(function (AffiliationReferral $ref) {
                return [
                    'id' => $ref->id,
                    'receiver_name' => $ref->receiver?->name ?? ('User #' . $ref->receiver_user_id),
                    'order_code' => $ref->order_code,
                    'yalidine_status' => $ref->order?->yalidine_parcel_status ?? '',
                    'issuer_commission_percent' => (float) $ref->issuer_commission_percent,
                    'issuer_commission_amount' => (float) $ref->issuer_commission_amount,
                    'is_credited' => (bool) $ref->is_credited,
                    'credited_at' => $ref->credited_at?->toIso8601String(),
                    'created_at' => $ref->created_at?->toIso8601String(),
                ];
            })
            ->values()
            ->all();

        $totalEarned = (float) AffiliationReferral::where('issuer_user_id', $userId)
            ->where('is_credited', true)
            ->sum('issuer_commission_amount');

        $alreadyUsedReferral = AffiliationReferral::where('receiver_user_id', $userId)->exists();

        return [
            'code' => $affCode->code,
            'is_active' => (bool) $affCode->is_active,
            'issuer_percentage' => (float) $settings->issuer_percentage,
            'receiver_percentage' => (float) $settings->receiver_percentage,
            'total_referrals' => count($referrals),
            'total_earned_dzd' => $totalEarned,
            'already_redeemed_as_receiver' => $alreadyUsedReferral,
            'referrals' => $referrals,
        ];
    }

    public function validateCode(string $rawCode, ?int $receiverUserId, float $subtotal): array
    {
        $code = strtoupper(trim($rawCode));
        if ($code === '') {
            return ['valid' => false, 'message' => 'Veuillez saisir un code de parrainage.', 'discount_amount' => 0.0];
        }

        if (!$receiverUserId || $receiverUserId <= 0) {
            return ['valid' => false, 'message' => 'Authentification requise pour utiliser un code de parrainage.', 'discount_amount' => 0.0];
        }

        $affCode = AffiliationCode::whereRaw('UPPER(TRIM(code)) = ?', [$code])->first();
        if (!$affCode) {
            return ['valid' => false, 'message' => 'Code de parrainage introuvable.', 'discount_amount' => 0.0];
        }

        if (!$affCode->is_active) {
            return ['valid' => false, 'message' => 'Ce code de parrainage a été désactivé.', 'discount_amount' => 0.0];
        }

        if ((int) $affCode->user_id === (int) $receiverUserId) {
            return ['valid' => false, 'message' => 'Vous ne pouvez pas utiliser votre propre code de parrainage.', 'discount_amount' => 0.0];
        }

        $alreadyUsed = AffiliationReferral::where('receiver_user_id', $receiverUserId)->exists();
        if ($alreadyUsed) {
            return ['valid' => false, 'message' => 'Vous avez déjà utilisé un code de parrainage sur votre compte.', 'discount_amount' => 0.0];
        }

        $settings = $this->getSettings();
        $receiverPct = max(0.0, (float) $settings->receiver_percentage);
        $discountAmount = round($subtotal * ($receiverPct / 100.0), 2);
        $discountAmount = max(0.0, min($subtotal, $discountAmount));

        return [
            'valid' => true,
            'message' => "Parrainage appliqué (-{$receiverPct}%).",
            'code' => $affCode->code,
            'affiliation_code_id' => $affCode->id,
            'issuer_user_id' => $affCode->user_id,
            'receiver_percentage' => $receiverPct,
            'issuer_percentage' => (float) $settings->issuer_percentage,
            'discount_amount' => $discountAmount,
            'new_subtotal' => max(0.0, round($subtotal - $discountAmount, 2)),
        ];
    }

    public function recordReferral(
        int $affiliationCodeId,
        int $issuerUserId,
        int $receiverUserId,
        int $orderId,
        string $orderCode,
        float $receiverPct,
        float $receiverDiscountAmount,
        float $issuerPct
    ): AffiliationReferral {
        return AffiliationReferral::create([
            'affiliation_code_id' => $affiliationCodeId,
            'issuer_user_id' => $issuerUserId,
            'receiver_user_id' => $receiverUserId,
            'order_id' => $orderId,
            'order_code' => $orderCode,
            'receiver_discount_percent' => $receiverPct,
            'receiver_discount_amount' => $receiverDiscountAmount,
            'issuer_commission_percent' => $issuerPct,
            'issuer_commission_amount' => 0.00,
            'is_credited' => false,
        ]);
    }

    /**
     * Credit the issuer's wallet when the referred order is delivered (idempotent).
     */
    public function creditIssuerForDeliveredOrder(Order $order): array
    {
        $existing = AffiliationReferral::where('order_id', $order->id)->first();
        if (!$existing) {
            return ['credited' => false, 'reason' => 'no_referral'];
        }
        if ((int) $existing->is_credited === 1 || !empty($existing->credited_at)) {
            return ['credited' => false, 'already_credited' => true];
        }

        return DB::transaction(function () use ($order) {
            $referral = AffiliationReferral::where('order_id', $order->id)->lockForUpdate()->first();
            if (!$referral || (int) $referral->is_credited === 1 || !empty($referral->credited_at)) {
                return ['credited' => false, 'already_credited' => true];
            }

            $existingTx = WalletTransaction::where('reference_id', 'aff_' . $referral->id)
                ->where('type', 'credit')
                ->where('source', 'affiliation_reward')
                ->first();

            if ($existingTx) {
                $referral->is_credited = true;
                $referral->credited_at = $existingTx->created_at ?? now();
                $referral->issuer_commission_amount = (float) $existingTx->amount;
                $referral->save();
                return ['credited' => false, 'already_credited' => true];
            }

            $order->loadMissing('orderItems');
            $itemsSum = (float) $order->orderItems->sum('sub_total');
            if ($itemsSum <= 0) {
                $itemsSum = max(0.0, (float) $order->total_price - (float) ($order->delivery_fee ?? 0));
            }
            $netOrderSubtotal = max(
                0.0,
                $itemsSum - (float) ($order->coupon_discount ?? 0) - (float) ($order->affiliation_discount ?? 0)
            );
            $commissionPct = max(0.0, (float) $referral->issuer_commission_percent);
            $commissionAmount = round($netOrderSubtotal * ($commissionPct / 100.0), 2);

            if ($commissionAmount > 0) {
                $walletService = app(WalletService::class);
                $wallet = $walletService->getOrCreateWalletForUser($referral->issuer_user_id);
                $lockedWallet = Wallet::where('id', $wallet->id)->lockForUpdate()->first();

                $balanceBefore = (float) $lockedWallet->balance;
                $balanceAfter = round($balanceBefore + $commissionAmount, 2);

                $lockedWallet->balance = $balanceAfter;
                $lockedWallet->save();

                WalletTransaction::create([
                    'wallet_id' => $lockedWallet->id,
                    'user_id' => $referral->issuer_user_id,
                    'type' => 'credit',
                    'source' => 'affiliation_reward',
                    'order_code' => $order->order_code,
                    'amount' => $commissionAmount,
                    'gross_amount' => $netOrderSubtotal,
                    'commission_amount' => 0.00,
                    'balance_before' => $balanceBefore,
                    'balance_after' => $balanceAfter,
                    'reference_id' => 'aff_' . $referral->id,
                    'description' => "Commission parrainage ({$commissionPct}%) pour la commande livrée #{$order->order_code}",
                ]);

                PushHelper::sendToUser(
                    (int) $referral->issuer_user_id,
                    "Vous avez reçu +{$commissionAmount} DA de commission parrainage pour la commande #{$order->order_code}.",
                    'wallet',
                    ['title' => 'Commission parrainage reçue']
                );
            }

            $referral->issuer_commission_amount = $commissionAmount;
            $referral->is_credited = true;
            $referral->credited_at = now();
            $referral->save();

            Log::info("Affiliation reward credited: {$commissionAmount} DZD to user #{$referral->issuer_user_id} for order #{$order->order_code}");

            return [
                'credited' => true,
                'amount' => $commissionAmount,
                'issuer_user_id' => $referral->issuer_user_id,
            ];
        });
    }
}
