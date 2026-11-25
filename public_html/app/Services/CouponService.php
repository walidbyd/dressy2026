<?php

namespace App\Services;

use App\Models\Coupon;
use App\Models\CouponUsage;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class CouponService
{
    public function generateUniqueCode(string $prefix = 'DRESSY'): string
    {
        do {
            $code = strtoupper($prefix . '-' . Str::upper(Str::random(6)));
        } while (Coupon::where('code', $code)->exists());

        return $code;
    }

    public function validateCoupon(string $rawCode, ?int $userId, float $subtotal): array
    {
        $code = strtoupper(trim($rawCode));
        if ($code === '') {
            return ['valid' => false, 'message' => 'Veuillez saisir un code promo.', 'discount_amount' => 0.0];
        }

        $coupon = Coupon::whereRaw('UPPER(TRIM(code)) = ?', [$code])->first();
        if (!$coupon) {
            return ['valid' => false, 'message' => 'Code promo invalide ou introuvable.', 'discount_amount' => 0.0];
        }

        if (!$coupon->is_active) {
            return ['valid' => false, 'message' => 'Ce code promo est désactivé.', 'discount_amount' => 0.0];
        }

        if ($coupon->expires_at && Carbon::parse($coupon->expires_at)->isPast()) {
            return ['valid' => false, 'message' => 'Ce code promo a expiré.', 'discount_amount' => 0.0];
        }

        if ($coupon->user_id !== null && (int) $coupon->user_id !== (int) $userId) {
            return ['valid' => false, 'message' => 'Ce code promo est réservé à un autre utilisateur.', 'discount_amount' => 0.0];
        }

        if ($coupon->max_uses !== null && (int) $coupon->used_count >= (int) $coupon->max_uses) {
            return ['valid' => false, 'message' => 'Ce code promo a atteint sa limite d\'utilisation.', 'discount_amount' => 0.0];
        }

        if ($userId && $coupon->max_uses_per_user !== null) {
            $userUses = CouponUsage::where('coupon_id', $coupon->id)
                ->where('user_id', $userId)
                ->count();
            if ($userUses >= (int) $coupon->max_uses_per_user) {
                return ['valid' => false, 'message' => 'Vous avez déjà utilisé ce code promo.', 'discount_amount' => 0.0];
            }
        }

        if ($coupon->min_order_amount !== null && $subtotal < (float) $coupon->min_order_amount) {
            $minFormatted = number_format((float) $coupon->min_order_amount, 0, '.', ' ');
            return [
                'valid' => false,
                'message' => "Montant minimum requis : {$minFormatted} DA.",
                'discount_amount' => 0.0,
            ];
        }

        $discountAmount = 0.0;
        if ($coupon->discount_type === 'percentage') {
            $discountAmount = round($subtotal * ((float) $coupon->discount_value / 100.0), 2);
        } else {
            $discountAmount = round((float) $coupon->discount_value, 2);
        }
        $discountAmount = max(0.0, min($subtotal, $discountAmount));

        return [
            'valid' => true,
            'message' => 'Code promo appliqué avec succès.',
            'discount_amount' => $discountAmount,
            'new_subtotal' => max(0.0, round($subtotal - $discountAmount, 2)),
            'coupon' => $this->formatCoupon($coupon),
        ];
    }

    public function recordUsage(int $couponId, int $userId, ?int $orderId, float $discountAmount): void
    {
        CouponUsage::create([
            'coupon_id' => $couponId,
            'user_id' => $userId,
            'order_id' => $orderId,
            'discount_amount' => $discountAmount,
        ]);

        Coupon::where('id', $couponId)->increment('used_count');
    }

    public function getUserAvailableCoupons(?int $userId): array
    {
        $now = Carbon::now();

        $coupons = Coupon::where('is_active', true)
            ->where(function ($q) use ($now) {
                $q->whereNull('expires_at')->orWhere('expires_at', '>', $now);
            })
            ->where(function ($q) use ($userId) {
                $q->whereNull('user_id');
                if ($userId) {
                    $q->orWhere('user_id', $userId);
                }
            })
            ->where(function ($q) {
                $q->whereNull('max_uses')->orWhereColumn('used_count', '<', 'max_uses');
            })
            ->orderByDesc('created_at')
            ->get();

        $result = [];
        foreach ($coupons as $coupon) {
            if ($userId && $coupon->max_uses_per_user !== null) {
                $usedByUser = CouponUsage::where('coupon_id', $coupon->id)
                    ->where('user_id', $userId)
                    ->count();
                if ($usedByUser >= (int) $coupon->max_uses_per_user) {
                    continue;
                }
            }
            $result[] = $this->formatCoupon($coupon);
        }

        return $result;
    }

    public function checkRouletteEligibility(?int $userId): array
    {
        if (!$userId) {
            return ['eligible' => false, 'reason' => 'unauthenticated'];
        }

        $user = DB::table('users')->select('id', 'last_roulette_spun_at')->where('id', $userId)->first();
        if (!$user) {
            return ['eligible' => false, 'reason' => 'user_not_found'];
        }

        if (empty($user->last_roulette_spun_at)) {
            return ['eligible' => true, 'next_spin_at' => null, 'remaining_seconds' => 0];
        }

        $nextSpinAt = Carbon::parse($user->last_roulette_spun_at)->addHours(24);
        if (Carbon::now()->gte($nextSpinAt)) {
            return ['eligible' => true, 'next_spin_at' => null, 'remaining_seconds' => 0];
        }

        return [
            'eligible' => false,
            'next_spin_at' => $nextSpinAt->toIso8601String(),
            'remaining_seconds' => max(0, Carbon::now()->diffInSeconds($nextSpinAt, false)),
        ];
    }

    public function spinRoulette(int $userId): array
    {
        $eligibility = $this->checkRouletteEligibility($userId);
        if (empty($eligibility['eligible'])) {
            return [
                'success' => false,
                'eligible' => false,
                'message' => 'Vous avez déjà tourné la roue aujourd\'hui. Revenez dans 24 heures.',
                'next_spin_at' => $eligibility['next_spin_at'] ?? null,
                'remaining_seconds' => $eligibility['remaining_seconds'] ?? 0,
            ];
        }

        $rewardPercent = random_int(0, 1) === 0 ? 5 : 10;
        $code = $this->generateUniqueCode('SPIN' . $rewardPercent);
        $expiresAt = Carbon::now()->addHours(24);

        $coupon = DB::transaction(function () use ($userId, $rewardPercent, $code, $expiresAt) {
            DB::table('users')->where('id', $userId)->update([
                'last_roulette_spun_at' => Carbon::now(),
            ]);

            return Coupon::create([
                'code' => $code,
                'discount_type' => 'percentage',
                'discount_value' => $rewardPercent,
                'min_order_amount' => null,
                'max_uses' => 1,
                'used_count' => 0,
                'max_uses_per_user' => 1,
                'user_id' => $userId,
                'source' => 'roulette',
                'is_active' => true,
                'expires_at' => $expiresAt,
            ]);
        });

        return [
            'success' => true,
            'eligible' => false,
            'reward_percent' => $rewardPercent,
            'coupon' => $this->formatCoupon($coupon),
            'next_spin_at' => Carbon::now()->addHours(24)->toIso8601String(),
        ];
    }

    public function formatCoupon(Coupon $coupon): array
    {
        $now = Carbon::now();
        $remainingSeconds = $coupon->expires_at
            ? max(0, $now->diffInSeconds(Carbon::parse($coupon->expires_at), false))
            : null;

        return [
            'id' => $coupon->id,
            'code' => $coupon->code,
            'discount_type' => $coupon->discount_type,
            'discount_value' => (float) $coupon->discount_value,
            'min_order_amount' => $coupon->min_order_amount !== null ? (float) $coupon->min_order_amount : null,
            'max_uses' => $coupon->max_uses,
            'used_count' => (int) $coupon->used_count,
            'max_uses_per_user' => $coupon->max_uses_per_user,
            'source' => $coupon->source ?? 'admin',
            'is_active' => (bool) $coupon->is_active,
            'expires_at' => $coupon->expires_at ? Carbon::parse($coupon->expires_at)->toIso8601String() : null,
            'remaining_seconds' => $remainingSeconds,
        ];
    }
}
