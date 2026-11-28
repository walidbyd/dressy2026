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

        $targetType = $coupon->target_type ?: ($coupon->user_id !== null ? 'user' : 'none');
        if ($targetType !== 'none' && !$this->isUserEligibleForCoupon($coupon, $userId)) {
            return ['valid' => false, 'message' => 'Ce code promo n\'est pas disponible pour votre compte.', 'discount_amount' => 0.0];
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

    public function isUserEligibleForCoupon(Coupon $coupon, ?int $userId): bool
    {
        $targetType = $coupon->target_type ?: ($coupon->user_id !== null ? 'user' : 'none');

        if ($targetType === 'none') {
            return false;
        }

        if ($userId === null || $userId <= 0) {
            return false;
        }

        if ($targetType === 'user') {
            return (int) $coupon->user_id === $userId;
        }

        if ($targetType === 'group') {
            $group = $coupon->target_group ?? 'all';
            if ($group === 'all') {
                return true;
            }
            if ($group === 'vendors') {
                return DB::table('psx_vendors')->where('owner_user_id', $userId)->exists();
            }
            if ($group === 'buyers') {
                return !DB::table('psx_vendors')->where('owner_user_id', $userId)->exists();
            }
            if ($group === 'selected') {
                $ids = array_map('intval', (array) ($coupon->target_user_ids ?? []));
                return in_array($userId, $ids, true);
            }
        }

        return false;
    }

    public function getUserAvailableCoupons(?int $userId): array
    {
        if (!$userId) {
            return [];
        }

        $now = Carbon::now();

        $coupons = Coupon::where('is_active', true)
            ->where(function ($q) use ($now) {
                $q->whereNull('expires_at')->orWhere('expires_at', '>', $now);
            })
            ->where(function ($q) use ($userId) {
                $q->where(function ($sub) use ($userId) {
                    $sub->where('target_type', 'user')->where('user_id', $userId);
                })
                ->orWhere('target_type', 'group')
                ->orWhere(function ($sub) use ($userId) {
                    // Backward compatibility for existing roulette coupons created before target_type existed
                    $sub->whereNull('target_type')->where('user_id', $userId);
                });
            })
            ->where(function ($q) {
                $q->whereNull('max_uses')->orWhereColumn('used_count', '<', 'max_uses');
            })
            ->orderByDesc('created_at')
            ->get();

        $result = [];
        foreach ($coupons as $coupon) {
            if (!$this->isUserEligibleForCoupon($coupon, $userId)) {
                continue;
            }
            if ($coupon->max_uses_per_user !== null) {
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

    public function getRouletteConfig(): array
    {
        $defaultSlices = [
            ['percent' => 5, 'label' => '-5%', 'weight' => 50, 'color' => '#3B82F6'],
            ['percent' => 20, 'label' => '-20%', 'weight' => 0, 'color' => '#EC4899'],
            ['percent' => 10, 'label' => '-10%', 'weight' => 50, 'color' => '#10B981'],
            ['percent' => 50, 'label' => '-50%', 'weight' => 0, 'color' => '#F59E0B'],
            ['percent' => 5, 'label' => '-5%', 'weight' => 0, 'color' => '#8B5CF6'],
            ['percent' => 10, 'label' => '-10%', 'weight' => 0, 'color' => '#EF4444'],
        ];

        try {
            $row = DB::table('psx_roulette_settings')->orderBy('id')->first();
            if ($row) {
                $decoded = is_string($row->slices) ? json_decode($row->slices, true) : $row->slices;
                $slices = (is_array($decoded) && count($decoded) >= 2) ? array_values($decoded) : $defaultSlices;
                return [
                    'is_enabled' => (bool) $row->is_enabled,
                    'slices' => $slices,
                ];
            }
        } catch (\Throwable $e) {
            // Table may not exist yet before migration
        }

        return [
            'is_enabled' => true,
            'slices' => $defaultSlices,
        ];
    }

    public function updateRouletteConfig(bool $isEnabled, array $slices): array
    {
        $normalized = [];
        foreach ($slices as $slice) {
            $percent = max(1, min(95, (int) ($slice['percent'] ?? 5)));
            $label = trim((string) ($slice['label'] ?? ('-' . $percent . '%')));
            if ($label === '') {
                $label = '-' . $percent . '%';
            }
            $weight = max(0, (int) ($slice['weight'] ?? 0));
            $color = trim((string) ($slice['color'] ?? '#3B82F6'));
            $normalized[] = [
                'percent' => $percent,
                'label' => $label,
                'weight' => $weight,
                'color' => $color !== '' ? $color : '#3B82F6',
            ];
        }

        $existing = DB::table('psx_roulette_settings')->orderBy('id')->first();
        if ($existing) {
            DB::table('psx_roulette_settings')->where('id', $existing->id)->update([
                'is_enabled' => $isEnabled,
                'slices' => json_encode($normalized),
                'updated_at' => Carbon::now(),
            ]);
        } else {
            DB::table('psx_roulette_settings')->insert([
                'is_enabled' => $isEnabled,
                'slices' => json_encode($normalized),
                'created_at' => Carbon::now(),
                'updated_at' => Carbon::now(),
            ]);
        }

        return ['is_enabled' => $isEnabled, 'slices' => $normalized];
    }

    public function checkRouletteEligibility(?int $userId): array
    {
        $config = $this->getRouletteConfig();
        if (!$config['is_enabled']) {
            return [
                'eligible' => false,
                'is_enabled' => false,
                'slices' => $config['slices'],
                'reason' => 'disabled',
            ];
        }

        if (!$userId) {
            return [
                'eligible' => false,
                'is_enabled' => true,
                'slices' => $config['slices'],
                'reason' => 'unauthenticated',
            ];
        }

        $user = DB::table('users')->select('id', 'last_roulette_spun_at')->where('id', $userId)->first();
        if (!$user) {
            return [
                'eligible' => false,
                'is_enabled' => true,
                'slices' => $config['slices'],
                'reason' => 'user_not_found',
            ];
        }

        if (empty($user->last_roulette_spun_at)) {
            return [
                'eligible' => true,
                'is_enabled' => true,
                'slices' => $config['slices'],
                'next_spin_at' => null,
                'remaining_seconds' => 0,
            ];
        }

        $nextSpinAt = Carbon::parse($user->last_roulette_spun_at)->addHours(24);
        if (Carbon::now()->gte($nextSpinAt)) {
            return [
                'eligible' => true,
                'is_enabled' => true,
                'slices' => $config['slices'],
                'next_spin_at' => null,
                'remaining_seconds' => 0,
            ];
        }

        return [
            'eligible' => false,
            'is_enabled' => true,
            'slices' => $config['slices'],
            'next_spin_at' => $nextSpinAt->toIso8601String(),
            'remaining_seconds' => max(0, Carbon::now()->diffInSeconds($nextSpinAt, false)),
        ];
    }

    public function spinRoulette(int $userId): array
    {
        $eligibility = $this->checkRouletteEligibility($userId);
        if (empty($eligibility['is_enabled'])) {
            return [
                'success' => false,
                'eligible' => false,
                'is_enabled' => false,
                'message' => 'La roue de la fortune est actuellement désactivée.',
            ];
        }
        if (empty($eligibility['eligible'])) {
            return [
                'success' => false,
                'eligible' => false,
                'is_enabled' => true,
                'message' => 'Vous avez déjà tourné la roue aujourd\'hui. Revenez dans 24 heures.',
                'next_spin_at' => $eligibility['next_spin_at'] ?? null,
                'remaining_seconds' => $eligibility['remaining_seconds'] ?? 0,
            ];
        }

        $slices = $eligibility['slices'] ?? [];
        $totalWeight = 0;
        foreach ($slices as $s) {
            $totalWeight += max(0, (int) ($s['weight'] ?? 0));
        }

        $selectedIdx = 0;
        if ($totalWeight > 0) {
            $roll = random_int(1, $totalWeight);
            $acc = 0;
            foreach ($slices as $idx => $s) {
                $acc += max(0, (int) ($s['weight'] ?? 0));
                if ($roll <= $acc) {
                    $selectedIdx = (int) $idx;
                    break;
                }
            }
        } elseif (!empty($slices)) {
            $selectedIdx = random_int(0, count($slices) - 1);
        }

        $rewardPercent = !empty($slices[$selectedIdx]['percent'])
            ? (int) $slices[$selectedIdx]['percent']
            : 5;
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
                'target_type' => 'user',
                'source' => 'roulette',
                'is_active' => true,
                'expires_at' => $expiresAt,
            ]);
        });

        return [
            'success' => true,
            'eligible' => false,
            'reward_percent' => $rewardPercent,
            'slice_index' => $selectedIdx,
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
            'target_type' => $coupon->target_type ?? ($coupon->user_id ? 'user' : 'none'),
            'target_group' => $coupon->target_group,
            'source' => $coupon->source ?? 'admin',
            'is_active' => (bool) $coupon->is_active,
            'expires_at' => $coupon->expires_at ? Carbon::parse($coupon->expires_at)->toIso8601String() : null,
            'remaining_seconds' => $remainingSeconds,
        ];
    }
}
