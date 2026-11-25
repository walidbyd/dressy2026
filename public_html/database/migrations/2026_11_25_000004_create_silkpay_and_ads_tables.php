<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('psx_silkpay_settings')) {
            Schema::create('psx_silkpay_settings', function (Blueprint $table) {
                $table->id();
                $table->string('webhook_secret', 255)->nullable();
                $table->string('api_key', 255)->nullable();
                $table->boolean('is_active')->default(true);
                $table->timestamps();
            });

            DB::table('psx_silkpay_settings')->insert([
                'webhook_secret' => '',
                'api_key' => '',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        if (!Schema::hasTable('psx_silkpay_packs')) {
            Schema::create('psx_silkpay_packs', function (Blueprint $table) {
                $table->id();
                $table->decimal('amount_dzd', 10, 2);
                $table->string('title', 120);
                $table->text('payment_url')->nullable();
                $table->boolean('is_active')->default(true);
                $table->integer('sort_order')->default(0);
                $table->timestamps();
            });

            DB::table('psx_silkpay_packs')->insert([
                ['amount_dzd' => 1000.00, 'title' => 'Pack 1 000 DA', 'payment_url' => '', 'is_active' => true, 'sort_order' => 1, 'created_at' => now(), 'updated_at' => now()],
                ['amount_dzd' => 2000.00, 'title' => 'Pack 2 000 DA', 'payment_url' => '', 'is_active' => true, 'sort_order' => 2, 'created_at' => now(), 'updated_at' => now()],
                ['amount_dzd' => 4000.00, 'title' => 'Pack 4 000 DA', 'payment_url' => '', 'is_active' => true, 'sort_order' => 3, 'created_at' => now(), 'updated_at' => now()],
                ['amount_dzd' => 6000.00, 'title' => 'Pack 6 000 DA', 'payment_url' => '', 'is_active' => true, 'sort_order' => 4, 'created_at' => now(), 'updated_at' => now()],
            ]);
        }

        if (!Schema::hasTable('psx_silkpay_transactions')) {
            Schema::create('psx_silkpay_transactions', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id')->index();
                $table->unsignedBigInteger('pack_id')->nullable()->index();
                $table->string('reference', 64)->unique();
                $table->decimal('amount_dzd', 10, 2);
                $table->text('payment_url')->nullable();
                $table->string('status', 24)->default('pending')->index();
                $table->string('gateway_tx_id', 128)->nullable();
                $table->json('webhook_payload')->nullable();
                $table->timestamp('credited_at')->nullable();
                $table->timestamps();
            });
        }

        if (!Schema::hasTable('psx_ad_settings')) {
            Schema::create('psx_ad_settings', function (Blueprint $table) {
                $table->id();
                $table->boolean('is_enabled')->default(true);
                $table->boolean('story_boost_enabled')->default(true);
                $table->decimal('story_boost_price_dzd', 10, 2)->default(300.00);
                $table->string('story_boost_title', 160)->default('Boost Story 24h');
                $table->text('story_boost_description')->nullable();
                $table->timestamps();
            });

            DB::table('psx_ad_settings')->insert([
                'is_enabled' => true,
                'story_boost_enabled' => true,
                'story_boost_price_dzd' => 300.00,
                'story_boost_title' => 'Boost Story 24h',
                'story_boost_description' => 'Placez votre story en tête de la barre d\'accueil pendant 24h pour maximiser vos vues et ventes.',
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        if (!Schema::hasTable('psx_ad_plans')) {
            Schema::create('psx_ad_plans', function (Blueprint $table) {
                $table->id();
                $table->string('tier', 24)->unique();
                $table->integer('duration_days');
                $table->string('title', 160);
                $table->text('description')->nullable();
                $table->decimal('price_dzd', 10, 2);
                $table->boolean('is_active')->default(true);
                $table->integer('sort_order')->default(0);
                $table->timestamps();
            });

            DB::table('psx_ad_plans')->insert([
                [
                    'tier' => 'daily',
                    'duration_days' => 1,
                    'title' => 'Boost 1 Jour',
                    'description' => 'Mettez votre article en avant avec le badge Sponsorisé pendant 24 heures.',
                    'price_dzd' => 200.00,
                    'is_active' => true,
                    'sort_order' => 1,
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'tier' => 'weekly',
                    'duration_days' => 7,
                    'title' => 'Boost 1 Semaine',
                    'description' => 'Visibilité prioritaire en tête des catégories et recherches pendant 7 jours.',
                    'price_dzd' => 1000.00,
                    'is_active' => true,
                    'sort_order' => 2,
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'tier' => 'monthly',
                    'duration_days' => 30,
                    'title' => 'Boost 1 Mois',
                    'description' => 'Exposition maximale vitrine & accueil pendant 30 jours complets.',
                    'price_dzd' => 3000.00,
                    'is_active' => true,
                    'sort_order' => 3,
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
            ]);
        }

        if (!Schema::hasTable('psx_ad_boosts')) {
            Schema::create('psx_ad_boosts', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id')->index();
                $table->unsignedBigInteger('vendor_id')->nullable()->index();
                $table->string('target_type', 16)->index(); // story | item
                $table->unsignedBigInteger('target_id')->index();
                $table->string('plan_tier', 24)->nullable();
                $table->decimal('amount_paid_dzd', 10, 2);
                $table->timestamp('starts_at');
                $table->timestamp('expires_at')->index();
                $table->timestamps();
            });
        }

        if (Schema::hasTable('psx_vendor_stories')) {
            Schema::table('psx_vendor_stories', function (Blueprint $table) {
                if (!Schema::hasColumn('psx_vendor_stories', 'is_boosted')) {
                    $table->boolean('is_boosted')->default(false);
                }
                if (!Schema::hasColumn('psx_vendor_stories', 'boost_expires_at')) {
                    $table->timestamp('boost_expires_at')->nullable();
                }
            });
        }

        if (Schema::hasTable('psx_items')) {
            Schema::table('psx_items', function (Blueprint $table) {
                if (!Schema::hasColumn('psx_items', 'is_boosted')) {
                    $table->boolean('is_boosted')->default(false);
                }
                if (!Schema::hasColumn('psx_items', 'boost_expires_at')) {
                    $table->timestamp('boost_expires_at')->nullable();
                }
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('psx_items')) {
            Schema::table('psx_items', function (Blueprint $table) {
                if (Schema::hasColumn('psx_items', 'boost_expires_at')) {
                    $table->dropColumn('boost_expires_at');
                }
                if (Schema::hasColumn('psx_items', 'is_boosted')) {
                    $table->dropColumn('is_boosted');
                }
            });
        }
        if (Schema::hasTable('psx_vendor_stories')) {
            Schema::table('psx_vendor_stories', function (Blueprint $table) {
                if (Schema::hasColumn('psx_vendor_stories', 'boost_expires_at')) {
                    $table->dropColumn('boost_expires_at');
                }
                if (Schema::hasColumn('psx_vendor_stories', 'is_boosted')) {
                    $table->dropColumn('is_boosted');
                }
            });
        }
        Schema::dropIfExists('psx_ad_boosts');
        Schema::dropIfExists('psx_ad_plans');
        Schema::dropIfExists('psx_ad_settings');
        Schema::dropIfExists('psx_silkpay_transactions');
        Schema::dropIfExists('psx_silkpay_packs');
        Schema::dropIfExists('psx_silkpay_settings');
    }
};
