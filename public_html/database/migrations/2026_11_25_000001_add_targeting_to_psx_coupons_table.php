<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('psx_coupons')) {
            Schema::table('psx_coupons', function (Blueprint $table) {
                if (!Schema::hasColumn('psx_coupons', 'target_type')) {
                    $table->string('target_type', 20)->default('none')->after('user_id');
                }
                if (!Schema::hasColumn('psx_coupons', 'target_group')) {
                    $table->string('target_group', 32)->nullable()->after('target_type');
                }
                if (!Schema::hasColumn('psx_coupons', 'target_user_ids')) {
                    $table->json('target_user_ids')->nullable()->after('target_group');
                }
            });

            DB::table('psx_coupons')
                ->whereNotNull('user_id')
                ->where('target_type', 'none')
                ->update(['target_type' => 'user']);
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('psx_coupons')) {
            Schema::table('psx_coupons', function (Blueprint $table) {
                if (Schema::hasColumn('psx_coupons', 'target_user_ids')) {
                    $table->dropColumn('target_user_ids');
                }
                if (Schema::hasColumn('psx_coupons', 'target_group')) {
                    $table->dropColumn('target_group');
                }
                if (Schema::hasColumn('psx_coupons', 'target_type')) {
                    $table->dropColumn('target_type');
                }
            });
        }
    }
};
