-- =====================================================================
-- Dressy C2C Production Database Cleanup & Algerian Localization Seed
-- =====================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
START TRANSACTION;

-- 1. Ensure Super Admin (biadwalid@gmail.com) is intact and active with sysadmin privileges
UPDATE `users` 
SET `role_id` = '1', `user_is_sys_admin` = 1, `status` = 1, `is_banned` = 0 
WHERE `email` = 'biadwalid@gmail.com' OR `id` = 1;

-- 2. Delete all demo users except biadwalid@gmail.com (id = 1)
DELETE FROM `users` WHERE `id` != 1 AND `email` != 'biadwalid@gmail.com';

-- 3. Delete user scoped dependent data for non-admin users
DELETE FROM `psx_user_infos` WHERE `user_id` != 1;
DELETE FROM `psx_user_address_information` WHERE `user_id` != 1;
DELETE FROM `psx_user_addresses` WHERE `user_id` != 1;
DELETE FROM `psx_user_access_api_tokens` WHERE `user_id` != 1;
DELETE FROM `psx_user_permissions` WHERE `user_id` != 1;
DELETE FROM `psx_push_notification_tokens` WHERE `user_id` != 1;
DELETE FROM `psx_push_notification_users` WHERE `user_id` != 1;
DELETE FROM `psx_blue_mark_users` WHERE `user_id` != 1;
DELETE FROM `psx_vendor_user_permissions` WHERE `user_id` != 1;
DELETE FROM `personal_access_tokens` WHERE `tokenable_id` != 1;

-- 4. Truncate demo transactions, items, orders, chats, and activities
TRUNCATE TABLE `psx_user_boughts`;
TRUNCATE TABLE `psx_follow_users`;
TRUNCATE TABLE `psx_block_users`;
TRUNCATE TABLE `psx_favourites`;
TRUNCATE TABLE `psx_ratings`;
TRUNCATE TABLE `psx_chat_histories`;
TRUNCATE TABLE `psx_chat_notis`;
TRUNCATE TABLE `psx_search_histories`;
TRUNCATE TABLE `psx_carts`;
TRUNCATE TABLE `psx_cart_items`;
TRUNCATE TABLE `psx_touches`;
TRUNCATE TABLE `psx_paid_item_histories`;
TRUNCATE TABLE `psx_package_bought_transactions`;
TRUNCATE TABLE `psx_subscription_bought_transactions`;
TRUNCATE TABLE `psx_transaction_counts`;
TRUNCATE TABLE `psx_transaction_details`;
TRUNCATE TABLE `psx_transaction_headers`;
TRUNCATE TABLE `psx_orders`;
TRUNCATE TABLE `psx_order_items`;
TRUNCATE TABLE `psx_shipping_and_billings`;
TRUNCATE TABLE `psx_vendor_transactions`;
TRUNCATE TABLE `psx_vendor_applications`;
TRUNCATE TABLE `psx_items`;
TRUNCATE TABLE `psx_item_infos`;
TRUNCATE TABLE `psx_item_reports`;
TRUNCATE TABLE `psx_wallet_transactions`;
TRUNCATE TABLE `psx_withdraw_requests`;

-- 5. Delete item images from psx_core_images (preserving branding & category icons)
DELETE FROM `psx_core_images` WHERE `img_type` IN ('item', 'item-video', 'item-video-icon');

-- 6. Vendor Cleanup: Keep Vendor 1 for Admin, Delete demo vendors
DELETE FROM `psx_vendors` WHERE `owner_user_id` != 1 AND `id` != 1;
UPDATE `psx_vendors` SET `status` = '2', `owner_user_id` = 1 WHERE `id` = 1;
DELETE FROM `psx_vendor_branches` WHERE `vendor_id` != 1;
DELETE FROM `psx_vendor_infos` WHERE `vendor_id` != 1;
DELETE FROM `psx_vendor_delivery_settings` WHERE `vendor_id` != 1;

-- 7. Initialize Admin Wallet (0.00 DZD)
DELETE FROM `psx_wallets` WHERE `user_id` != 1;
INSERT INTO `psx_wallets` (`id`, `user_id`, `vendor_id`, `balance`, `currency_code`, `created_at`, `updated_at`)
VALUES (1, 1, 1, 0.00, 'DZD', NOW(), NOW())
ON DUPLICATE KEY UPDATE `vendor_id` = 1, `balance` = 0.00, `currency_code` = 'DZD', `updated_at` = NOW();

-- 8. Currency Configuration: Enforce DZD (DA) as sole active & default currency
UPDATE `psx_currencies` SET `status` = 0, `is_default` = 0;
INSERT INTO `psx_currencies` (`id`, `currency_symbol`, `currency_short_form`, `status`, `is_default`, `added_date`, `added_user_id`)
VALUES (1, 'DA', 'DZD', 1, 1, NOW(), 1)
ON DUPLICATE KEY UPDATE `currency_symbol` = 'DA', `currency_short_form` = 'DZD', `status` = 1, `is_default` = 1, `updated_date` = NOW();

UPDATE `psx_vendors` SET `currency_id` = 1 WHERE `id` = 1;

UPDATE `psx_available_currencies` SET `status` = 0, `is_default` = 0;
UPDATE `psx_available_currencies` SET `status` = 1, `is_default` = 1 WHERE `id` = 129 OR `currency_short_form` = 'DZD';

-- 9. Payment Gateways: Enforce COD Only (payment00009)
UPDATE `psx_payments` SET `status` = 0 WHERE `id` != 'payment00009';
UPDATE `psx_payments` SET `status` = 1 WHERE `id` = 'payment00009';

DELETE FROM `psx_vendor_payments` WHERE `vendor_id` != 1;
UPDATE `psx_vendor_payments` SET `status` = 0 WHERE `vendor_id` = 1 AND `payment_id` != 'payment00009';
INSERT INTO `psx_vendor_payments` (`vendor_id`, `payment_id`, `status`, `added_date`, `added_user_id`)
VALUES (1, 'payment00009', 1, NOW(), 1)
ON DUPLICATE KEY UPDATE `status` = 1, `updated_date` = NOW();

-- 10. Algerian Localization: Seed all 58 Wilayas
TRUNCATE TABLE `psx_location_townships`;
TRUNCATE TABLE `psx_location_cities`;

INSERT INTO `psx_location_cities` (`id`, `name`, `lat`, `lng`, `ordering`, `status`, `description`, `touch_count`, `is_featured`, `added_date`, `added_user_id`) VALUES
(1, '01 - Adrar', '27.8742', '-0.2939', 1, 1, 'Wilaya de Adrar', 0, 0, NOW(), 1),
(2, '02 - Chlef', '36.1652', '1.3345', 2, 1, 'Wilaya de Chlef', 0, 0, NOW(), 1),
(3, '03 - Laghouat', '33.8000', '2.8651', 3, 1, 'Wilaya de Laghouat', 0, 0, NOW(), 1),
(4, '04 - Oum El Bouaghi', '35.8755', '7.1135', 4, 1, 'Wilaya de Oum El Bouaghi', 0, 0, NOW(), 1),
(5, '05 - Batna', '35.5558', '6.1741', 5, 1, 'Wilaya de Batna', 0, 0, NOW(), 1),
(6, '06 - Béjaïa', '36.7509', '5.0567', 6, 1, 'Wilaya de Béjaïa', 0, 0, NOW(), 1),
(7, '07 - Biskra', '34.8504', '5.7281', 7, 1, 'Wilaya de Biskra', 0, 0, NOW(), 1),
(8, '08 - Béchar', '31.6167', '-2.2167', 8, 1, 'Wilaya de Béchar', 0, 0, NOW(), 1),
(9, '09 - Blida', '36.4700', '2.8277', 9, 1, 'Wilaya de Blida', 0, 0, NOW(), 1),
(10, '10 - Bouira', '36.3749', '3.9020', 10, 1, 'Wilaya de Bouira', 0, 0, NOW(), 1),
(11, '11 - Tamanrasset', '22.7850', '5.5228', 11, 1, 'Wilaya de Tamanrasset', 0, 0, NOW(), 1),
(12, '12 - Tébessa', '35.4042', '8.1242', 12, 1, 'Wilaya de Tébessa', 0, 0, NOW(), 1),
(13, '13 - Tlemcen', '34.8783', '-1.3150', 13, 1, 'Wilaya de Tlemcen', 0, 0, NOW(), 1),
(14, '14 - Tiaret', '35.3710', '1.3170', 14, 1, 'Wilaya de Tiaret', 0, 0, NOW(), 1),
(15, '15 - Tizi Ouzou', '36.7118', '4.0459', 15, 1, 'Wilaya de Tizi Ouzou', 0, 0, NOW(), 1),
(16, '16 - Alger', '36.7538', '3.0588', 16, 1, 'Wilaya de Alger', 0, 0, NOW(), 1),
(17, '17 - Djelfa', '34.6728', '3.2630', 17, 1, 'Wilaya de Djelfa', 0, 0, NOW(), 1),
(18, '18 - Jijel', '36.8206', '5.7667', 18, 1, 'Wilaya de Jijel', 0, 0, NOW(), 1),
(19, '19 - Sétif', '36.1911', '5.4137', 19, 1, 'Wilaya de Sétif', 0, 0, NOW(), 1),
(20, '20 - Saïda', '34.8303', '0.1517', 20, 1, 'Wilaya de Saïda', 0, 0, NOW(), 1),
(21, '21 - Skikda', '36.8762', '6.9092', 21, 1, 'Wilaya de Skikda', 0, 0, NOW(), 1),
(22, '22 - Sidi Bel Abbès', '35.1899', '-0.6309', 22, 1, 'Wilaya de Sidi Bel Abbès', 0, 0, NOW(), 1),
(23, '23 - Annaba', '36.9000', '7.7667', 23, 1, 'Wilaya de Annaba', 0, 0, NOW(), 1),
(24, '24 - Guelma', '36.4621', '7.4261', 24, 1, 'Wilaya de Guelma', 0, 0, NOW(), 1),
(25, '25 - Constantine', '36.3650', '6.6147', 25, 1, 'Wilaya de Constantine', 0, 0, NOW(), 1),
(26, '26 - Médéa', '36.2642', '2.7539', 26, 1, 'Wilaya de Médéa', 0, 0, NOW(), 1),
(27, '27 - Mostaganem', '35.9312', '0.0892', 27, 1, 'Wilaya de Mostaganem', 0, 0, NOW(), 1),
(28, '28 - M\'Sila', '35.7058', '4.5419', 28, 1, 'Wilaya de M\'Sila', 0, 0, NOW(), 1),
(29, '29 - Mascara', '35.3966', '0.1403', 29, 1, 'Wilaya de Mascara', 0, 0, NOW(), 1),
(30, '30 - Ouargla', '31.9493', '5.3250', 30, 1, 'Wilaya de Ouargla', 0, 0, NOW(), 1),
(31, '31 - Oran', '35.6987', '-0.6349', 31, 1, 'Wilaya de Oran', 0, 0, NOW(), 1),
(32, '32 - El Bayadh', '33.6832', '1.0193', 32, 1, 'Wilaya de El Bayadh', 0, 0, NOW(), 1),
(33, '33 - Illizi', '26.4833', '8.4667', 33, 1, 'Wilaya de Illizi', 0, 0, NOW(), 1),
(34, '34 - Bordj Bou Arreridj', '36.0731', '4.7611', 34, 1, 'Wilaya de Bordj Bou Arreridj', 0, 0, NOW(), 1),
(35, '35 - Boumerdès', '36.7599', '3.4728', 35, 1, 'Wilaya de Boumerdès', 0, 0, NOW(), 1),
(36, '36 - El Tarf', '36.7672', '8.3138', 36, 1, 'Wilaya de El Tarf', 0, 0, NOW(), 1),
(37, '37 - Tindouf', '27.6711', '-8.1474', 37, 1, 'Wilaya de Tindouf', 0, 0, NOW(), 1),
(38, '38 - Tissemsilt', '35.6072', '1.8108', 38, 1, 'Wilaya de Tissemsilt', 0, 0, NOW(), 1),
(39, '39 - El Oued', '33.3683', '6.8674', 39, 1, 'Wilaya de El Oued', 0, 0, NOW(), 1),
(40, '40 - Khenchela', '35.4358', '7.1433', 40, 1, 'Wilaya de Khenchela', 0, 0, NOW(), 1),
(41, '41 - Souk Ahras', '36.2864', '7.9511', 41, 1, 'Wilaya de Souk Ahras', 0, 0, NOW(), 1),
(42, '42 - Tipaza', '36.5897', '2.4475', 42, 1, 'Wilaya de Tipaza', 0, 0, NOW(), 1),
(43, '43 - Mila', '36.4503', '6.2644', 43, 1, 'Wilaya de Mila', 0, 0, NOW(), 1),
(44, '44 - Aïn Defla', '36.2641', '1.9679', 44, 1, 'Wilaya de Aïn Defla', 0, 0, NOW(), 1),
(45, '45 - Naâma', '33.2667', '-0.3167', 45, 1, 'Wilaya de Naâma', 0, 0, NOW(), 1),
(46, '46 - Aïn Témouchent', '35.2975', '-1.1404', 46, 1, 'Wilaya de Aïn Témouchent', 0, 0, NOW(), 1),
(47, '47 - Ghardaïa', '32.4909', '3.6735', 47, 1, 'Wilaya de Ghardaïa', 0, 0, NOW(), 1),
(48, '48 - Relizane', '35.7373', '0.5558', 48, 1, 'Wilaya de Relizane', 0, 0, NOW(), 1),
(49, '49 - Timimoun', '29.2639', '0.2310', 49, 1, 'Wilaya de Timimoun', 0, 0, NOW(), 1),
(50, '50 - Bordj Badji Mokhtar', '21.3283', '0.9547', 50, 1, 'Wilaya de Bordj Badji Mokhtar', 0, 0, NOW(), 1),
(51, '51 - Ouled Djellal', '34.4333', '5.0667', 51, 1, 'Wilaya de Ouled Djellal', 0, 0, NOW(), 1),
(52, '52 - Béni Abbès', '30.0833', '-2.1667', 52, 1, 'Wilaya de Béni Abbès', 0, 0, NOW(), 1),
(53, '53 - In Salah', '27.1936', '2.4608', 53, 1, 'Wilaya de In Salah', 0, 0, NOW(), 1),
(54, '54 - In Guezzam', '19.5686', '5.7694', 54, 1, 'Wilaya de In Guezzam', 0, 0, NOW(), 1),
(55, '55 - Touggourt', '33.1064', '6.0594', 55, 1, 'Wilaya de Touggourt', 0, 0, NOW(), 1),
(56, '56 - Djanet', '24.5531', '9.4858', 56, 1, 'Wilaya de Djanet', 0, 0, NOW(), 1),
(57, '57 - El M\'Ghair', '33.9500', '5.9167', 57, 1, 'Wilaya de El M\'Ghair', 0, 0, NOW(), 1),
(58, '58 - El Meniaa', '30.5833', '2.8833', 58, 1, 'Wilaya de El Meniaa', 0, 0, NOW(), 1);

COMMIT;
SET FOREIGN_KEY_CHECKS = 1;
