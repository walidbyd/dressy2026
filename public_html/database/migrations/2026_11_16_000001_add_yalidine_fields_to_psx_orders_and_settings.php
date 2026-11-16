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
        // 1. Add Yalidine & Delivery fields to psx_orders
        Schema::table('psx_orders', function (Blueprint $table) {
            if (!Schema::hasColumn('psx_orders', 'delivery_type')) {
                $table->string('delivery_type', 20)->default('home')->after('order_status_id');
            }
            if (!Schema::hasColumn('psx_orders', 'from_wilaya_id')) {
                $table->integer('from_wilaya_id')->nullable()->after('delivery_type');
            }
            if (!Schema::hasColumn('psx_orders', 'to_wilaya_id')) {
                $table->integer('to_wilaya_id')->nullable()->after('from_wilaya_id');
            }
            if (!Schema::hasColumn('psx_orders', 'to_commune_name')) {
                $table->string('to_commune_name', 120)->nullable()->after('to_wilaya_id');
            }
            if (!Schema::hasColumn('psx_orders', 'yalidine_stop_desk_id')) {
                $table->integer('yalidine_stop_desk_id')->nullable()->after('to_commune_name');
            }
            if (!Schema::hasColumn('psx_orders', 'yalidine_tracking')) {
                $table->string('yalidine_tracking', 100)->nullable()->index()->after('yalidine_stop_desk_id');
            }
            if (!Schema::hasColumn('psx_orders', 'yalidine_label_url')) {
                $table->text('yalidine_label_url')->nullable()->after('yalidine_tracking');
            }
            if (!Schema::hasColumn('psx_orders', 'yalidine_parcel_status')) {
                $table->string('yalidine_parcel_status', 100)->nullable()->after('yalidine_label_url');
            }
        });

        // 2. Add Yalidine API credentials to psx_backend_settings
        Schema::table('psx_backend_settings', function (Blueprint $table) {
            if (!Schema::hasColumn('psx_backend_settings', 'yalidine_api_id')) {
                $table->string('yalidine_api_id', 255)->nullable()->after('map_key');
            }
            if (!Schema::hasColumn('psx_backend_settings', 'yalidine_api_token')) {
                $table->string('yalidine_api_token', 255)->nullable()->after('yalidine_api_id');
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
            $colsToDrop = [];
            foreach ([
                'delivery_type',
                'from_wilaya_id',
                'to_wilaya_id',
                'to_commune_name',
                'yalidine_stop_desk_id',
                'yalidine_label_url',
                'yalidine_parcel_status'
            ] as $col) {
                if (Schema::hasColumn('psx_orders', $col)) {
                    $colsToDrop[] = $col;
                }
            }
            if (!empty($colsToDrop)) {
                $table->dropColumn($colsToDrop);
            }
        });

        Schema::table('psx_backend_settings', function (Blueprint $table) {
            $colsToDrop = [];
            foreach (['yalidine_api_id', 'yalidine_api_token'] as $col) {
                if (Schema::hasColumn('psx_backend_settings', $col)) {
                    $colsToDrop[] = $col;
                }
            }
            if (!empty($colsToDrop)) {
                $table->dropColumn($colsToDrop);
            }
        });
    }
};
