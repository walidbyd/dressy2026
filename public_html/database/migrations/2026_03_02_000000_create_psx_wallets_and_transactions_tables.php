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
        if (!Schema::hasTable('psx_wallets')) {
            Schema::create('psx_wallets', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id')->unique();
                $table->unsignedBigInteger('vendor_id')->nullable();
                $table->decimal('balance', 12, 2)->default(0.00);
                $table->string('currency_code', 10)->default('DZD');
                $table->timestamps();
            });
        }

        if (!Schema::hasTable('psx_wallet_transactions')) {
            Schema::create('psx_wallet_transactions', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('wallet_id')->index();
                $table->unsignedBigInteger('user_id')->index();
                $table->string('type', 20); // credit, debit
                $table->decimal('amount', 12, 2);
                $table->decimal('balance_after', 12, 2);
                $table->string('reference_type', 50)->nullable(); // order, withdraw
                $table->string('reference_id', 50)->nullable(); // order_id, withdraw_id
                $table->text('note')->nullable();
                $table->unsignedBigInteger('added_user_id')->nullable();
                $table->timestamps();
            });
        }

        if (!Schema::hasTable('psx_withdraw_requests')) {
            Schema::create('psx_withdraw_requests', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('wallet_id')->index();
                $table->unsignedBigInteger('user_id')->index();
                $table->decimal('amount', 12, 2);
                $table->string('status', 20)->default('pending'); // pending, approved, rejected
                $table->text('note')->nullable();
                $table->timestamps();
            });
        }

        Schema::table('psx_orders', function (Blueprint $table) {
            if (!Schema::hasColumn('psx_orders', 'is_wallet_credited')) {
                $table->tinyInteger('is_wallet_credited')->default(0)->after('yalidine_status');
            }
            if (!Schema::hasColumn('psx_orders', 'wallet_credited_at')) {
                $table->timestamp('wallet_credited_at')->nullable()->after('is_wallet_credited');
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
        Schema::table('psx_orders', function (Blueprint $table) {
            $columns = [];
            if (Schema::hasColumn('psx_orders', 'is_wallet_credited')) {
                $columns[] = 'is_wallet_credited';
            }
            if (Schema::hasColumn('psx_orders', 'wallet_credited_at')) {
                $columns[] = 'wallet_credited_at';
            }
            if (!empty($columns)) {
                $table->dropColumn($columns);
            }
        });

        Schema::dropIfExists('psx_withdraw_requests');
        Schema::dropIfExists('psx_wallet_transactions');
        Schema::dropIfExists('psx_wallets');
    }
};
