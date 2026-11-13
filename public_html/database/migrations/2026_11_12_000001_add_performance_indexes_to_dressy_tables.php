<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
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
        $indexes = [
            'users' => [
                'users_email_index' => ['email'],
                'users_role_id_index' => ['role_id'],
            ],
            'psx_vendors' => [
                'psx_vendors_owner_user_id_index' => ['owner_user_id'],
                'psx_vendors_status_index' => ['status'],
                'psx_vendors_currency_id_index' => ['currency_id'],
            ],
            'psx_items' => [
                'psx_items_category_id_index' => ['category_id'],
                'psx_items_subcategory_id_index' => ['subcategory_id'],
                'psx_items_is_sold_out_index' => ['is_sold_out'],
            ],
            'psx_orders' => [
                'psx_orders_user_id_index' => ['user_id'],
                'psx_orders_vendor_id_index' => ['vendor_id'],
                'psx_orders_order_code_index' => ['order_code'],
                'psx_orders_order_status_id_index' => ['order_status_id'],
                'psx_orders_is_wallet_credited_index' => ['is_wallet_credited'],
                'psx_orders_yalidine_tracking_index' => ['yalidine_tracking'],
            ],
            'psx_order_items' => [
                'psx_order_items_order_id_index' => ['order_id'],
                'psx_order_items_item_id_index' => ['item_id'],
            ],
            'psx_shipping_and_billings' => [
                'psx_shipping_and_billings_order_id_index' => ['order_id'],
                'psx_shipping_and_billings_shipping_city_index' => ['shipping_city'],
                'psx_shipping_and_billings_shipping_state_index' => ['shipping_state'],
            ],
            'psx_wallets' => [
                'psx_wallets_vendor_id_index' => ['vendor_id'],
            ],
            'psx_wallet_transactions' => [
                'psx_wallet_transactions_type_index' => ['type'],
                'psx_wallet_transactions_reference_index' => ['reference_type', 'reference_id'],
            ],
            'psx_withdraw_requests' => [
                'psx_withdraw_requests_status_index' => ['status'],
            ],
            'psx_location_cities' => [
                'psx_location_cities_status_index' => ['status'],
                'psx_location_cities_ordering_index' => ['ordering'],
            ],
        ];

        foreach ($indexes as $table => $tableIndexes) {
            if (!Schema::hasTable($table)) {
                continue;
            }

            $existingIndexes = collect(DB::select("SHOW INDEX FROM `{$table}`"))
                ->pluck('Key_name')
                ->unique()
                ->toArray();

            Schema::table($table, function (Blueprint $blueprint) use ($table, $tableIndexes, $existingIndexes) {
                foreach ($tableIndexes as $indexName => $columns) {
                    if (!in_array($indexName, $existingIndexes)) {
                        // Check if all columns exist on the table
                        $missingCol = false;
                        foreach ($columns as $col) {
                            if (!Schema::hasColumn($table, $col)) {
                                $missingCol = true;
                                break;
                            }
                        }

                        if (!$missingCol) {
                            $blueprint->index($columns, $indexName);
                        }
                    }
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        $indexes = [
            'users' => ['users_email_index', 'users_role_id_index'],
            'psx_vendors' => ['psx_vendors_owner_user_id_index', 'psx_vendors_status_index', 'psx_vendors_currency_id_index'],
            'psx_items' => ['psx_items_category_id_index', 'psx_items_subcategory_id_index', 'psx_items_is_sold_out_index'],
            'psx_orders' => [
                'psx_orders_user_id_index', 'psx_orders_vendor_id_index', 'psx_orders_order_code_index',
                'psx_orders_order_status_id_index', 'psx_orders_is_wallet_credited_index', 'psx_orders_yalidine_tracking_index'
            ],
            'psx_order_items' => ['psx_order_items_order_id_index', 'psx_order_items_item_id_index'],
            'psx_shipping_and_billings' => [
                'psx_shipping_and_billings_order_id_index', 'psx_shipping_and_billings_shipping_city_index', 'psx_shipping_and_billings_shipping_state_index'
            ],
            'psx_wallets' => ['psx_wallets_vendor_id_index'],
            'psx_wallet_transactions' => ['psx_wallet_transactions_type_index', 'psx_wallet_transactions_reference_index'],
            'psx_withdraw_requests' => ['psx_withdraw_requests_status_index'],
            'psx_location_cities' => ['psx_location_cities_status_index', 'psx_location_cities_ordering_index'],
        ];

        foreach ($indexes as $table => $tableIndexes) {
            if (!Schema::hasTable($table)) {
                continue;
            }

            $existingIndexes = collect(DB::select("SHOW INDEX FROM `{$table}`"))
                ->pluck('Key_name')
                ->unique()
                ->toArray();

            Schema::table($table, function (Blueprint $blueprint) use ($tableIndexes, $existingIndexes) {
                foreach ($tableIndexes as $indexName) {
                    if (in_array($indexName, $existingIndexes)) {
                        $blueprint->dropIndex($indexName);
                    }
                }
            });
        }
    }
};
