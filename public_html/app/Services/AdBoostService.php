<?php

namespace App\Services;

use App\Models\AdBoost;
use App\Models\AdPlan;
use App\Models\AdSetting;
use App\Models\VendorStory;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Modules\Core\Entities\Item\Item;
use Modules\Core\Entities\Vendor\Vendor;
use Modules\StoreFront\VendorPanel\Entities\Wallet;
use Modules\StoreFront\VendorPanel\Entities\WalletTransaction;
use Modules\StoreFront\VendorPanel\Http\Services\WalletService;

class AdBoostService
{
    public function getSettings(): AdSetting
    {
        $s = AdSetting::first();
        if (!$s) {
            $s = AdSetting::create([
                'is_enabled' => true,
                'story_boost_enabled' => true,
                'story_boost_price_dzd' => 300.00,
                'story_boost_title' => 'Boost Story 24h',
                'story_boost_description' => 'Placez votre story en tête de la barre d\'accueil pendant 24h.',
            ]);
        }
        return $s;
    }

    public function getPublicConfig(): array
    {
        $settings = $this->getSettings();
        $plans = AdPlan::orderBy('sort_order')->get()->map(fn (AdPlan $p) => [
            'id' => $p->id,
            'tier' => $p->tier,
            'duration_days' => (int) $p->duration_days,
            'title' => $p->title,
            'description' => $p->description ?? '',
            'price_dzd' => (float) $p->price_dzd,
            'is_active' => (bool) $p->is_active,
        ])->values()->all();

        return [
            'is_enabled' => (bool) $settings->is_enabled,
            'story_boost' => [
                'enabled' => (bool) ($settings->is_enabled && $settings->story_boost_enabled),
                'price_dzd' => (float) $settings->story_boost_price_dzd,
                'title' => $settings->story_boost_title,
                'description' => $settings->story_boost_description ?? '',
            ],
            'item_plans' => $plans,
        ];
    }

    public function boostStory(int $userId, int $storyId): array
    {
        $settings = $this->getSettings();
        if (!$settings->is_enabled || !$settings->story_boost_enabled) {
            return ['success' => false, 'status_code' => 422, 'message' => 'Le boost de story est actuellement désactivé.'];
        }

        $story = VendorStory::where('id', $storyId)->where('user_id', $userId)->first();
        if (!$story) {
            return ['success' => false, 'status_code' => 404, 'message' => 'Story introuvable.'];
        }

        $now = Carbon::now();
        if ($story->is_boosted && $story->boost_expires_at && Carbon::parse($story->boost_expires_at)->gt($now)) {
            return ['success' => false, 'status_code' => 422, 'message' => 'Cette story est déjà boostée.'];
        }

        $price = max(0.0, (float) $settings->story_boost_price_dzd);

        return DB::transaction(function () use ($userId, $story, $price, $now) {
            $walletService = app(WalletService::class);
            $wallet = $walletService->getOrCreateWalletForUser($userId, $story->vendor_id);
            $lockedWallet = Wallet::where('id', $wallet->id)->lockForUpdate()->first();

            $balanceBefore = (float) $lockedWallet->balance;
            if ($balanceBefore < $price) {
                return [
                    'success' => false,
                    'status_code' => 402,
                    'insufficient_balance' => true,
                    'wallet_balance' => $balanceBefore,
                    'required_amount' => $price,
                    'message' => 'Solde Wallet insuffisant pour booster cette story.',
                ];
            }

            $balanceAfter = round($balanceBefore - $price, 2);
            if ($price > 0) {
                $lockedWallet->balance = $balanceAfter;
                $lockedWallet->save();

                WalletTransaction::create([
                    'wallet_id' => $lockedWallet->id,
                    'user_id' => $userId,
                    'type' => 'debit',
                    'source' => 'ad_story_boost',
                    'order_code' => 'STORY-' . $story->id,
                    'amount' => $price,
                    'gross_amount' => $price,
                    'commission_amount' => 0.00,
                    'balance_before' => $balanceBefore,
                    'balance_after' => $balanceAfter,
                    'reference_id' => 'story_boost_' . $story->id . '_' . time(),
                    'description' => 'Boost Story 24h',
                ]);

                PushHelper::sendToUser(
                    (int) $userId,
                    "Boost Story 24h activé (-{$price} DA débités de votre portefeuille).",
                    'wallet',
                    ['title' => 'Boost Story activé']
                );
            }

            $expiresAt = $now->copy()->addHours(24);
            $story->is_boosted = true;
            $story->boost_expires_at = $expiresAt;
            if (!$story->expires_at || Carbon::parse($story->expires_at)->lt($expiresAt)) {
                $story->expires_at = $expiresAt;
            }
            $story->save();

            $boost = AdBoost::create([
                'user_id' => $userId,
                'vendor_id' => $story->vendor_id,
                'target_type' => 'story',
                'target_id' => $story->id,
                'plan_tier' => 'story_24h',
                'amount_paid_dzd' => $price,
                'starts_at' => $now,
                'expires_at' => $expiresAt,
            ]);

            return [
                'success' => true,
                'status_code' => 200,
                'message' => 'Votre story est maintenant boostée pour 24h !',
                'boost' => $boost,
                'wallet_balance' => $balanceAfter,
            ];
        });
    }

    public function boostItem(int $userId, int $itemId, string $tier): array
    {
        $settings = $this->getSettings();
        if (!$settings->is_enabled) {
            return ['success' => false, 'status_code' => 422, 'message' => 'La publicité est actuellement désactivée.'];
        }

        $plan = AdPlan::where('tier', $tier)->where('is_active', true)->first();
        if (!$plan) {
            return ['success' => false, 'status_code' => 404, 'message' => 'Formule de boost introuvable ou désactivée.'];
        }

        $item = Item::find($itemId);
        if (!$item) {
            return ['success' => false, 'status_code' => 404, 'message' => 'Article introuvable.'];
        }

        $vendorId = $item->vendor_id;
        $ownsItem = ((int) $item->added_user_id === $userId)
            || ($vendorId && Vendor::where('id', $vendorId)->where('owner_user_id', $userId)->exists());

        if (!$ownsItem) {
            return ['success' => false, 'status_code' => 403, 'message' => 'Vous ne pouvez booster que vos propres articles.'];
        }

        $now = Carbon::now();
        $price = max(0.0, (float) $plan->price_dzd);

        return DB::transaction(function () use ($userId, $item, $vendorId, $plan, $price, $now) {
            $walletService = app(WalletService::class);
            $wallet = $walletService->getOrCreateWalletForUser($userId, $vendorId);
            $lockedWallet = Wallet::where('id', $wallet->id)->lockForUpdate()->first();

            $balanceBefore = (float) $lockedWallet->balance;
            if ($balanceBefore < $price) {
                return [
                    'success' => false,
                    'status_code' => 402,
                    'insufficient_balance' => true,
                    'wallet_balance' => $balanceBefore,
                    'required_amount' => $price,
                    'message' => 'Solde Wallet insuffisant pour ce boost.',
                ];
            }

            $balanceAfter = round($balanceBefore - $price, 2);
            if ($price > 0) {
                $lockedWallet->balance = $balanceAfter;
                $lockedWallet->save();

                WalletTransaction::create([
                    'wallet_id' => $lockedWallet->id,
                    'user_id' => $userId,
                    'type' => 'debit',
                    'source' => 'ad_item_boost',
                    'order_code' => 'ITEM-' . $item->id,
                    'amount' => $price,
                    'gross_amount' => $price,
                    'commission_amount' => 0.00,
                    'balance_before' => $balanceBefore,
                    'balance_after' => $balanceAfter,
                    'reference_id' => 'item_boost_' . $item->id . '_' . time(),
                    'description' => "Boost Article - {$plan->title}",
                ]);

                PushHelper::sendToUser(
                    (int) $userId,
                    "Boost Article ({$plan->title}) activé (-{$price} DA débités de votre portefeuille).",
                    'wallet',
                    ['title' => 'Boost Article activé', 'item_id' => (string) $item->id]
                );
            }

            $expiresAt = $now->copy()->addDays((int) $plan->duration_days);
            $item->is_boosted = true;
            $item->boost_expires_at = $expiresAt;
            $item->save();

            $boost = AdBoost::create([
                'user_id' => $userId,
                'vendor_id' => $vendorId,
                'target_type' => 'item',
                'target_id' => $item->id,
                'plan_tier' => $plan->tier,
                'amount_paid_dzd' => $price,
                'starts_at' => $now,
                'expires_at' => $expiresAt,
            ]);

            return [
                'success' => true,
                'status_code' => 200,
                'message' => "Votre article est maintenant Sponsorisé ({$plan->title}) !",
                'boost' => $boost,
                'wallet_balance' => $balanceAfter,
            ];
        });
    }
}
