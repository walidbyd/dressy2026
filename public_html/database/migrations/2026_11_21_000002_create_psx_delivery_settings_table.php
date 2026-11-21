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
        // 1. Delivery settings table
        if (!Schema::hasTable('psx_delivery_settings')) {
            Schema::create('psx_delivery_settings', function (Blueprint $table) {
                $table->id();
                $table->boolean('is_enabled')->default(true);
                $table->string('environment', 20)->default('production'); // production, sandbox
                $table->string('api_base_url', 255)->default('https://api.yalidine.app/v1');
                $table->string('api_id', 100)->nullable();
                $table->text('api_token')->nullable(); // Encrypted via Crypt::encryptString
                $table->boolean('auto_create_parcel')->default(true);
                $table->string('auto_sync_trigger', 50)->default('on_seller_confirmed'); // on_order_placed, on_seller_confirmed, manual_only
                $table->boolean('auto_sync_status')->default(true);
                $table->string('webhook_secret', 100)->nullable();
                $table->string('sender_name', 150)->default('Dressy DZ');
                $table->string('sender_phone', 50)->default('0550000000');
                $table->integer('from_wilaya_id')->default(16);
                $table->string('from_commune_name', 150)->nullable()->default('Alger');
                $table->string('from_stop_desk_id', 50)->nullable();
                $table->string('default_delivery_type', 30)->default('home'); // home, stop_desk
                $table->boolean('is_free_shipping')->default(false);
                $table->decimal('free_shipping_min_amount', 12, 2)->nullable()->default(0.00);
                $table->boolean('has_insurance')->default(false);
                $table->boolean('open_parcel')->default(true);
                $table->string('description_prefix', 150)->default('Article Mode Dressy');
                $table->timestamps();
            });
        }

        // 2. Add wallet_reversed_at to psx_orders if not present
        Schema::table('psx_orders', function (Blueprint $table) {
            if (!Schema::hasColumn('psx_orders', 'wallet_reversed_at')) {
                $table->timestamp('wallet_reversed_at')->nullable()->after('wallet_credited_at');
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
        Schema::dropIfExists('psx_delivery_settings');

        Schema::table('psx_orders', function (Blueprint $table) {
            if (Schema::hasColumn('psx_orders', 'wallet_reversed_at')) {
                $table->dropColumn('wallet_reversed_at');
            }
        });
    }
};
