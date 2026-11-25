<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('psx_affiliation_settings')) {
            Schema::create('psx_affiliation_settings', function (Blueprint $table) {
                $table->id();
                $table->decimal('issuer_percentage', 5, 2)->default(10.00);
                $table->decimal('receiver_percentage', 5, 2)->default(10.00);
                $table->timestamps();
            });

            DB::table('psx_affiliation_settings')->insert([
                'issuer_percentage' => 10.00,
                'receiver_percentage' => 10.00,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        if (!Schema::hasTable('psx_affiliation_codes')) {
            Schema::create('psx_affiliation_codes', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id')->unique();
                $table->string('code', 32)->unique();
                $table->boolean('is_active')->default(true);
                $table->timestamps();
            });
        }

        if (!Schema::hasTable('psx_affiliation_referrals')) {
            Schema::create('psx_affiliation_referrals', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('affiliation_code_id')->index();
                $table->unsignedBigInteger('issuer_user_id')->index();
                $table->unsignedBigInteger('receiver_user_id')->unique();
                $table->unsignedBigInteger('order_id')->nullable()->index();
                $table->string('order_code', 64)->nullable();
                $table->decimal('receiver_discount_percent', 5, 2)->default(10.00);
                $table->decimal('receiver_discount_amount', 10, 2)->default(0.00);
                $table->decimal('issuer_commission_percent', 5, 2)->default(10.00);
                $table->decimal('issuer_commission_amount', 10, 2)->default(0.00);
                $table->boolean('is_credited')->default(false);
                $table->timestamp('credited_at')->nullable();
                $table->timestamps();
            });
        }

        if (Schema::hasTable('psx_orders')) {
            Schema::table('psx_orders', function (Blueprint $table) {
                if (!Schema::hasColumn('psx_orders', 'affiliation_code')) {
                    $table->string('affiliation_code', 32)->nullable();
                }
                if (!Schema::hasColumn('psx_orders', 'affiliation_discount')) {
                    $table->decimal('affiliation_discount', 10, 2)->default(0.00);
                }
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('psx_orders')) {
            Schema::table('psx_orders', function (Blueprint $table) {
                if (Schema::hasColumn('psx_orders', 'affiliation_discount')) {
                    $table->dropColumn('affiliation_discount');
                }
                if (Schema::hasColumn('psx_orders', 'affiliation_code')) {
                    $table->dropColumn('affiliation_code');
                }
            });
        }

        Schema::dropIfExists('psx_affiliation_referrals');
        Schema::dropIfExists('psx_affiliation_codes');
        Schema::dropIfExists('psx_affiliation_settings');
    }
};
