<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('psx_wallet_transactions', function (Blueprint $table) {
            if (!Schema::hasColumn('psx_wallet_transactions', 'source')) {
                $table->string('source', 50)->nullable()->default('sale_earning')->after('type');
            }
            if (!Schema::hasColumn('psx_wallet_transactions', 'order_code')) {
                $table->string('order_code', 50)->nullable()->index()->after('source');
            }
            if (!Schema::hasColumn('psx_wallet_transactions', 'gross_amount')) {
                $table->decimal('gross_amount', 12, 2)->nullable()->default(0.00)->after('amount');
            }
            if (!Schema::hasColumn('psx_wallet_transactions', 'commission_amount')) {
                $table->decimal('commission_amount', 12, 2)->nullable()->default(0.00)->after('gross_amount');
            }
            if (!Schema::hasColumn('psx_wallet_transactions', 'description')) {
                $table->text('description')->nullable()->after('note');
            }
        });

        Schema::table('psx_orders', function (Blueprint $table) {
            if (!Schema::hasColumn('psx_orders', 'payment_status')) {
                $table->string('payment_status', 20)->nullable()->default('pending')->after('order_status_id');
            }
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('psx_wallet_transactions', function (Blueprint $table) {
            $cols = [];
            foreach (['source', 'order_code', 'gross_amount', 'commission_amount', 'description'] as $col) {
                if (Schema::hasColumn('psx_wallet_transactions', $col)) {
                    $cols[] = $col;
                }
            }
            if (!empty($cols)) {
                $table->dropColumn($cols);
            }
        });

        Schema::table('psx_orders', function (Blueprint $table) {
            if (Schema::hasColumn('psx_orders', 'payment_status')) {
                $table->dropColumn('payment_status');
            }
        });
    }
};
