<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    private function addIndexIfMissing(string $table, array $columns, string $indexName)
    {
        if (!Schema::hasTable($table)) {
            return;
        }

        try {
            $indices = DB::select("SHOW INDEX FROM `{$table}` WHERE Key_name = ?", [$indexName]);
            if (empty($indices)) {
                Schema::table($table, function (Blueprint $table) use ($columns, $indexName) {
                    $table->index($columns, $indexName);
                });
            }
        } catch (\Throwable $e) {
            // Silently ignore if index already exists or table cannot be inspected
        }
    }

    private function dropIndexIfExists(string $table, string $indexName)
    {
        if (!Schema::hasTable($table)) {
            return;
        }

        try {
            $indices = DB::select("SHOW INDEX FROM `{$table}` WHERE Key_name = ?", [$indexName]);
            if (!empty($indices)) {
                Schema::table($table, function (Blueprint $table) use ($indexName) {
                    $table->dropIndex($indexName);
                });
            }
        } catch (\Throwable $e) {
            // Silently ignore if index not found
        }
    }

    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        // 1. psx_items
        $this->addIndexIfMissing('psx_items', ['status', 'is_sold_out'], 'idx_psx_items_status_soldout');
        $this->addIndexIfMissing('psx_items', ['added_user_id'], 'idx_psx_items_added_user_id');
        $this->addIndexIfMissing('psx_items', ['vendor_id'], 'idx_psx_items_vendor_id');
        $this->addIndexIfMissing('psx_items', ['category_id', 'subcategory_id'], 'idx_psx_items_cat_subcat');

        // 2. psx_item_infos
        $this->addIndexIfMissing('psx_item_infos', ['item_id', 'core_keys_id'], 'idx_psx_item_infos_item_corekey');

        // 3. psx_orders
        $this->addIndexIfMissing('psx_orders', ['user_id', 'order_status_id'], 'idx_psx_orders_user_status');
        $this->addIndexIfMissing('psx_orders', ['vendor_id'], 'idx_psx_orders_vendor_id');

        // 4. psx_order_items
        $this->addIndexIfMissing('psx_order_items', ['order_id', 'item_id'], 'idx_psx_order_items_order_item');

        // 5. psx_chat_histories
        $this->addIndexIfMissing('psx_chat_histories', ['buyer_user_id', 'seller_user_id', 'item_id'], 'idx_psx_chat_buyer_seller_item');

        // 6. psx_favourites
        $this->addIndexIfMissing('psx_favourites', ['user_id', 'item_id'], 'idx_psx_favourites_user_item');

        // 7. psx_follow_users
        $this->addIndexIfMissing('psx_follow_users', ['user_id', 'followed_user_id'], 'idx_psx_follows_user_followed');
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        $this->dropIndexIfExists('psx_items', 'idx_psx_items_status_soldout');
        $this->dropIndexIfExists('psx_items', 'idx_psx_items_added_user_id');
        $this->dropIndexIfExists('psx_items', 'idx_psx_items_vendor_id');
        $this->dropIndexIfExists('psx_items', 'idx_psx_items_cat_subcat');
        $this->dropIndexIfExists('psx_item_infos', 'idx_psx_item_infos_item_corekey');
        $this->dropIndexIfExists('psx_orders', 'idx_psx_orders_user_status');
        $this->dropIndexIfExists('psx_orders', 'idx_psx_orders_vendor_id');
        $this->dropIndexIfExists('psx_order_items', 'idx_psx_order_items_order_item');
        $this->dropIndexIfExists('psx_chat_histories', 'idx_psx_chat_buyer_seller_item');
        $this->dropIndexIfExists('psx_favourites', 'idx_psx_favourites_user_item');
        $this->dropIndexIfExists('psx_follow_users', 'idx_psx_follows_user_followed');
    }
};
