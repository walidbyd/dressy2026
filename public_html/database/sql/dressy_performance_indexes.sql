-- =====================================================================
-- Dressy C2C Performance Indexing Script
-- =====================================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS CreateIndexIfNotExists $$
CREATE PROCEDURE CreateIndexIfNotExists(
    IN targetTable VARCHAR(64),
    IN indexName VARCHAR(64),
    IN indexColumns VARCHAR(255)
)
BEGIN
    DECLARE indexCount INT;
    SELECT COUNT(*) INTO indexCount
    FROM INFORMATION_SCHEMA.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = targetTable
      AND INDEX_NAME = indexName;

    IF indexCount = 0 THEN
        SET @sqlQuery = CONCAT('CREATE INDEX `', indexName, '` ON `', targetTable, '` (', indexColumns, ');');
        PREPARE stmt FROM @sqlQuery;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END $$

DELIMITER ;

-- 1. Users
CALL CreateIndexIfNotExists('users', 'users_email_index', '`email`');
CALL CreateIndexIfNotExists('users', 'users_role_id_index', '`role_id`');

-- 2. Vendors
CALL CreateIndexIfNotExists('psx_vendors', 'psx_vendors_owner_user_id_index', '`owner_user_id`');
CALL CreateIndexIfNotExists('psx_vendors', 'psx_vendors_status_index', '`status`');
CALL CreateIndexIfNotExists('psx_vendors', 'psx_vendors_currency_id_index', '`currency_id`');

-- 3. Items
CALL CreateIndexIfNotExists('psx_items', 'psx_items_category_id_index', '`category_id`');
CALL CreateIndexIfNotExists('psx_items', 'psx_items_subcategory_id_index', '`subcategory_id`');
CALL CreateIndexIfNotExists('psx_items', 'psx_items_is_sold_out_index', '`is_sold_out`');

-- 4. Orders
CALL CreateIndexIfNotExists('psx_orders', 'psx_orders_user_id_index', '`user_id`');
CALL CreateIndexIfNotExists('psx_orders', 'psx_orders_vendor_id_index', '`vendor_id`');
CALL CreateIndexIfNotExists('psx_orders', 'psx_orders_order_code_index', '`order_code`');
CALL CreateIndexIfNotExists('psx_orders', 'psx_orders_order_status_id_index', '`order_status_id`');
CALL CreateIndexIfNotExists('psx_orders', 'psx_orders_is_wallet_credited_index', '`is_wallet_credited`');
CALL CreateIndexIfNotExists('psx_orders', 'psx_orders_yalidine_tracking_index', '`yalidine_tracking`');

-- 5. Order Items
CALL CreateIndexIfNotExists('psx_order_items', 'psx_order_items_order_id_index', '`order_id`');
CALL CreateIndexIfNotExists('psx_order_items', 'psx_order_items_item_id_index', '`item_id`');

-- 6. Shipping & Billing
CALL CreateIndexIfNotExists('psx_shipping_and_billings', 'psx_shipping_and_billings_order_id_index', '`order_id`');
CALL CreateIndexIfNotExists('psx_shipping_and_billings', 'psx_shipping_and_billings_shipping_city_index', '`shipping_city`');
CALL CreateIndexIfNotExists('psx_shipping_and_billings', 'psx_shipping_and_billings_shipping_state_index', '`shipping_state`');

-- 7. Wallets
CALL CreateIndexIfNotExists('psx_wallets', 'psx_wallets_vendor_id_index', '`vendor_id`');

-- 8. Wallet Transactions
CALL CreateIndexIfNotExists('psx_wallet_transactions', 'psx_wallet_transactions_type_index', '`type`');
CALL CreateIndexIfNotExists('psx_wallet_transactions', 'psx_wallet_transactions_reference_index', '`reference_type`, `reference_id`');

-- 9. Withdraw Requests
CALL CreateIndexIfNotExists('psx_withdraw_requests', 'psx_withdraw_requests_status_index', '`status`');

-- 10. Cities / Wilayas
CALL CreateIndexIfNotExists('psx_location_cities', 'psx_location_cities_status_index', '`status`');
CALL CreateIndexIfNotExists('psx_location_cities', 'psx_location_cities_ordering_index', '`ordering`');

DROP PROCEDURE IF EXISTS CreateIndexIfNotExists;
