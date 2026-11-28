<?php

namespace App\Services;

use App\Models\SilkpayPack;
use App\Models\SilkpaySetting;
use App\Models\SilkpayTransaction;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Modules\StoreFront\VendorPanel\Entities\Wallet;
use Modules\StoreFront\VendorPanel\Entities\WalletTransaction;
use Modules\StoreFront\VendorPanel\Http\Services\WalletService;

class SilkpayService
{
    public function getSettings(): SilkpaySetting
    {
        $s = SilkpaySetting::first();
        if (!$s) {
            $s = SilkpaySetting::create([
                'webhook_secret' => '',
                'api_key' => '',
                'is_active' => true,
            ]);
        }
        return $s;
    }

    public function getActivePacks()
    {
        return SilkpayPack::where('is_active', true)
            ->orderBy('sort_order')
            ->orderBy('amount_dzd')
            ->get();
    }

    public function initiateTopup(int $userId, int $packId): array
    {
        $settings = $this->getSettings();
        if (!$settings->is_active) {
            return ['success' => false, 'status_code' => 422, 'message' => 'Le rechargement Silk Pay est temporairement désactivé.'];
        }

        $pack = SilkpayPack::where('id', $packId)->where('is_active', true)->first();
        if (!$pack) {
            return ['success' => false, 'status_code' => 404, 'message' => 'Pack de rechargement introuvable ou inactif.'];
        }

        if (empty(trim((string) $pack->payment_url))) {
            return ['success' => false, 'status_code' => 422, 'message' => 'Le lien de paiement Silk Pay pour ce pack n\'est pas encore configuré.'];
        }

        $reference = 'SP-' . date('Ymd') . '-' . Str::upper(Str::random(8));
        $paymentUrl = trim((string) $pack->payment_url);
        $sep = str_contains($paymentUrl, '?') ? '&' : '?';
        $fullUrl = $paymentUrl . $sep . http_build_query([
            'reference' => $reference,
            'user_id' => $userId,
            'amount' => (int) $pack->amount_dzd,
        ]);

        $tx = SilkpayTransaction::create([
            'user_id' => $userId,
            'pack_id' => $pack->id,
            'reference' => $reference,
            'amount_dzd' => $pack->amount_dzd,
            'payment_url' => $fullUrl,
            'status' => 'pending',
        ]);

        return [
            'success' => true,
            'status_code' => 200,
            'transaction' => [
                'id' => $tx->id,
                'reference' => $tx->reference,
                'amount_dzd' => (float) $tx->amount_dzd,
                'status' => $tx->status,
                'payment_url' => $fullUrl,
            ],
        ];
    }

    public function handleWebhook(array $payload, ?string $signatureHeader, string $rawBody): array
    {
        $settings = $this->getSettings();
        $secret = trim((string) ($settings->webhook_secret ?? ''));

        if ($secret !== '') {
            $sig = trim((string) ($signatureHeader ?? ''));
            $computedHex = hash_hmac('sha256', $rawBody, $secret);
            if ($sig === '' || (!hash_equals($computedHex, $sig) && !hash_equals($secret, $sig))) {
                Log::warning('Silkpay webhook invalid signature.');
                return ['success' => false, 'status_code' => 401, 'message' => 'Invalid signature'];
            }
        }

        $reference = (string) ($payload['reference'] ?? $payload['order_id'] ?? $payload['merchant_reference'] ?? '');
        $gatewayTxId = (string) ($payload['transaction_id'] ?? $payload['tx_id'] ?? $payload['id'] ?? '');
        $rawStatus = strtolower(trim((string) ($payload['status'] ?? $payload['payment_status'] ?? '')));

        $tx = null;
        if ($reference !== '') {
            $tx = SilkpayTransaction::where('reference', $reference)->first();
        }
        if (!$tx && $gatewayTxId !== '') {
            $tx = SilkpayTransaction::where('gateway_tx_id', $gatewayTxId)->first();
        }

        if (!$tx) {
            Log::warning("Silkpay webhook: transaction not found for reference={$reference}");
            return ['success' => false, 'status_code' => 404, 'message' => 'Transaction not found'];
        }

        if (in_array($rawStatus, ['paid', 'success', 'succeeded', 'completed', 'credited', 'approved', '1', 'true'], true)) {
            $res = $this->creditTransaction($tx, $payload, $gatewayTxId ?: null);
            return ['success' => true, 'status_code' => 200, 'result' => $res];
        }

        if (in_array($rawStatus, ['failed', 'canceled', 'cancelled', 'rejected', 'expired', '0', 'false'], true)) {
            $res = $this->cancelTransaction($tx, $payload, $gatewayTxId ?: null);
            return ['success' => true, 'status_code' => 200, 'result' => $res];
        }

        return ['success' => true, 'status_code' => 200, 'message' => 'Ignored status: ' . $rawStatus];
    }

    public function creditTransaction(SilkpayTransaction $tx, ?array $payload = null, ?string $gatewayTxId = null): array
    {
        if ($tx->status === 'credited' && !empty($tx->credited_at)) {
            return ['credited' => false, 'already_credited' => true];
        }

        return DB::transaction(function () use ($tx, $payload, $gatewayTxId) {
            $lockedTx = SilkpayTransaction::where('id', $tx->id)->lockForUpdate()->first();
            if (!$lockedTx || ($lockedTx->status === 'credited' && !empty($lockedTx->credited_at))) {
                return ['credited' => false, 'already_credited' => true];
            }

            $refKey = 'silkpay_' . $lockedTx->id;
            $existingWalletTx = WalletTransaction::where('reference_id', $refKey)
                ->where('type', 'credit')
                ->where('source', 'silkpay_topup')
                ->first();

            if (!$existingWalletTx) {
                $walletService = app(WalletService::class);
                $wallet = $walletService->getOrCreateWalletForUser($lockedTx->user_id);
                $lockedWallet = Wallet::where('id', $wallet->id)->lockForUpdate()->first();

                $amount = (float) $lockedTx->amount_dzd;
                $balanceBefore = (float) $lockedWallet->balance;
                $balanceAfter = round($balanceBefore + $amount, 2);

                $lockedWallet->balance = $balanceAfter;
                $lockedWallet->save();

                WalletTransaction::create([
                    'wallet_id' => $lockedWallet->id,
                    'user_id' => $lockedTx->user_id,
                    'type' => 'credit',
                    'source' => 'silkpay_topup',
                    'order_code' => $lockedTx->reference,
                    'amount' => $amount,
                    'gross_amount' => $amount,
                    'commission_amount' => 0.00,
                    'balance_before' => $balanceBefore,
                    'balance_after' => $balanceAfter,
                    'reference_id' => $refKey,
                    'description' => "Rechargement CIB / Edahabia (Silk Pay) • {$lockedTx->reference}",
                ]);

                PushHelper::sendToUser(
                    (int) $lockedTx->user_id,
                    "Votre portefeuille a été rechargé de {$amount} DA via CIB / Edahabia (Silk Pay).",
                    'wallet',
                    ['title' => 'Portefeuille rechargé']
                );
            }

            $lockedTx->status = 'credited';
            $lockedTx->credited_at = Carbon::now();
            if ($gatewayTxId) {
                $lockedTx->gateway_tx_id = $gatewayTxId;
            }
            if ($payload !== null) {
                $lockedTx->webhook_payload = $payload;
            }
            $lockedTx->save();

            return ['credited' => true, 'amount' => (float) $lockedTx->amount_dzd];
        });
    }

    public function cancelTransaction(SilkpayTransaction $tx, ?array $payload = null, ?string $gatewayTxId = null): array
    {
        if ($tx->status === 'credited') {
            return ['canceled' => false, 'message' => 'Déjà créditée.'];
        }

        $tx->status = 'canceled';
        if ($gatewayTxId) {
            $tx->gateway_tx_id = $gatewayTxId;
        }
        if ($payload !== null) {
            $tx->webhook_payload = $payload;
        }
        $tx->save();

        return ['canceled' => true];
    }
}
