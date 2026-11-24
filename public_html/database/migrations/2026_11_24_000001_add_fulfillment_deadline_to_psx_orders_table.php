<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('psx_orders') && !Schema::hasColumn('psx_orders', 'fulfillment_deadline_at')) {
            Schema::table('psx_orders', function (Blueprint $table) {
                $table->timestamp('fulfillment_deadline_at')->nullable()->after('status_reason');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('psx_orders') && Schema::hasColumn('psx_orders', 'fulfillment_deadline_at')) {
            Schema::table('psx_orders', function (Blueprint $table) {
                $table->dropColumn('fulfillment_deadline_at');
            });
        }
    }
};
