-- ==============================================================================
-- DRESSY C2C MARKETPLACE: VINTED-STYLE 2-LEVEL CATEGORY TAXONOMY
-- CATEGORIES: Women (Femme / نساء) & Baby (Bébé / أطفال رضع)
-- File: database/sql/dressy_vinted_categories.sql
-- ==============================================================================

SET FOREIGN_KEY_CHECKS = 0;
START TRANSACTION;

-- 1. Wipe existing categories, subcategories, language strings, subscriptions
TRUNCATE TABLE `psx_category_language_strings`;
TRUNCATE TABLE `psx_sub_category_language_strings`;
TRUNCATE TABLE `psx_subcat_subscribes`;
TRUNCATE TABLE `psx_subcategories`;
TRUNCATE TABLE `psx_categories`;

DELETE FROM `psx_core_images` WHERE `img_type` IN ('category-cover', 'category-icon', 'subcategory-cover', 'subcategory-icon');

-- 2. Insert Category 1: Women
INSERT INTO `psx_categories` (`id`, `name`, `ordering`, `status`, `added_date`, `added_user_id`)
VALUES (1, 'Women', 1, 1, NOW(), 1);

-- Category 1 Language Strings (1: en, 2: ar, 3: fr)
INSERT INTO `psx_category_language_strings` (`category_id`, `language_id`, `key`, `value`, `added_date`, `added_user_id`) VALUES
(1, 1, 'Women', 'Women', NOW(), 1),
(1, 2, 'Women', 'نساء', NOW(), 1),
(1, 3, 'Women', 'Femme', NOW(), 1);

-- Category 1 Images
INSERT INTO `psx_core_images` (`img_parent_id`, `img_type`, `img_path`, `ordering`) VALUES
(1, 'category-cover', '6556eef6ae7ca_.png', 1),
(1, 'category-icon', '6556eef709c2e_.png', 1);

-- Subcategories for Women (13 subcategories)
INSERT INTO `psx_subcategories` (`id`, `category_id`, `name`, `ordering`, `status`, `added_date`, `added_user_id`) VALUES
(1, 1, 'Dresses', 1, 1, NOW(), 1),
(2, 1, 'Tops & T-Shirts', 2, 1, NOW(), 1),
(3, 1, 'Sweaters & Cardigans', 3, 1, NOW(), 1),
(4, 1, 'Coats & Jackets', 4, 1, NOW(), 1),
(5, 1, 'Jeans & Trousers', 5, 1, NOW(), 1),
(6, 1, 'Skirts & Shorts', 6, 1, NOW(), 1),
(7, 1, 'Suits & Blazers', 7, 1, NOW(), 1),
(8, 1, 'Activewear & Loungewear', 8, 1, NOW(), 1),
(9, 1, 'Swimwear & Lingerie', 9, 1, NOW(), 1),
(10, 1, 'Traditional & Occasion Wear', 10, 1, NOW(), 1),
(11, 1, 'Shoes', 11, 1, NOW(), 1),
(12, 1, 'Bags & Backpacks', 12, 1, NOW(), 1),
(13, 1, 'Accessories & Jewelry', 13, 1, NOW(), 1);

-- Subcategory Language Strings for Women (1: en, 2: ar, 3: fr)
INSERT INTO `psx_sub_category_language_strings` (`subcategory_id`, `language_id`, `key`, `value`, `added_date`, `added_user_id`) VALUES
(1, 1, 'Dresses', 'Dresses', NOW(), 1),
(1, 2, 'Dresses', 'فساتين', NOW(), 1),
(1, 3, 'Dresses', 'Robes', NOW(), 1),

(2, 1, 'Tops & T-Shirts', 'Tops & T-Shirts', NOW(), 1),
(2, 2, 'Tops & T-Shirts', 'بلوزات وتيشيرتات', NOW(), 1),
(2, 3, 'Tops & T-Shirts', 'Hauts & T-shirts', NOW(), 1),

(3, 1, 'Sweaters & Cardigans', 'Sweaters & Cardigans', NOW(), 1),
(3, 2, 'Sweaters & Cardigans', 'كنزات وسترات صوفية', NOW(), 1),
(3, 3, 'Sweaters & Cardigans', 'Pulls & Gilets', NOW(), 1),

(4, 1, 'Coats & Jackets', 'Coats & Jackets', NOW(), 1),
(4, 2, 'Coats & Jackets', 'معاطف وجاكيتات', NOW(), 1),
(4, 3, 'Coats & Jackets', 'Manteaux & Vestes', NOW(), 1),

(5, 1, 'Jeans & Trousers', 'Jeans & Trousers', NOW(), 1),
(5, 2, 'Jeans & Trousers', 'جينز وسراويل', NOW(), 1),
(5, 3, 'Jeans & Trousers', 'Jeans & Pantalons', NOW(), 1),

(6, 1, 'Skirts & Shorts', 'Skirts & Shorts', NOW(), 1),
(6, 2, 'Skirts & Shorts', 'تنانير وشورتات', NOW(), 1),
(6, 3, 'Skirts & Shorts', 'Jupes & Shorts', NOW(), 1),

(7, 1, 'Suits & Blazers', 'Suits & Blazers', NOW(), 1),
(7, 2, 'Suits & Blazers', 'بدل وبليزر', NOW(), 1),
(7, 3, 'Suits & Blazers', 'Tailleurs & Blazers', NOW(), 1),

(8, 1, 'Activewear & Loungewear', 'Activewear & Loungewear', NOW(), 1),
(8, 2, 'Activewear & Loungewear', 'ملابس رياضية ومنزلية', NOW(), 1),
(8, 3, 'Activewear & Loungewear', 'Sport & Détente', NOW(), 1),

(9, 1, 'Swimwear & Lingerie', 'Swimwear & Lingerie', NOW(), 1),
(9, 2, 'Swimwear & Lingerie', 'ملابس سباحة ولانجري', NOW(), 1),
(9, 3, 'Swimwear & Lingerie', 'Maillots de bain & Lingerie', NOW(), 1),

(10, 1, 'Traditional & Occasion Wear', 'Traditional & Occasion Wear', NOW(), 1),
(10, 2, 'Traditional & Occasion Wear', 'أزياء تقليدية وسهرات', NOW(), 1),
(10, 3, 'Traditional & Occasion Wear', 'Tenues traditionnelles & Soirée', NOW(), 1),

(11, 1, 'Shoes', 'Shoes', NOW(), 1),
(11, 2, 'Shoes', 'أحذية', NOW(), 1),
(11, 3, 'Shoes', 'Chaussures', NOW(), 1),

(12, 1, 'Bags & Backpacks', 'Bags & Backpacks', NOW(), 1),
(12, 2, 'Bags & Backpacks', 'حقائب', NOW(), 1),
(12, 3, 'Bags & Backpacks', 'Sacs & Sacs à dos', NOW(), 1),

(13, 1, 'Accessories & Jewelry', 'Accessories & Jewelry', NOW(), 1),
(13, 2, 'Accessories & Jewelry', 'إكسسوارات ومجوهرات', NOW(), 1),
(13, 3, 'Accessories & Jewelry', 'Accessoires & Bijoux', NOW(), 1);

-- 3. Insert Category 2: Baby
INSERT INTO `psx_categories` (`id`, `name`, `ordering`, `status`, `added_date`, `added_user_id`)
VALUES (2, 'Baby', 2, 1, NOW(), 1);

-- Category 2 Language Strings (1: en, 2: ar, 3: fr)
INSERT INTO `psx_category_language_strings` (`category_id`, `language_id`, `key`, `value`, `added_date`, `added_user_id`) VALUES
(2, 1, 'Baby', 'Baby', NOW(), 1),
(2, 2, 'Baby', 'أطفال رضع', NOW(), 1),
(2, 3, 'Baby', 'Bébé', NOW(), 1);

-- Category 2 Images
INSERT INTO `psx_core_images` (`img_parent_id`, `img_type`, `img_path`, `ordering`) VALUES
(2, 'category-cover', '6556ef8667151_.png', 1),
(2, 'category-icon', '6556ef86abdd1_.png', 1);

-- Subcategories for Baby (10 subcategories)
INSERT INTO `psx_subcategories` (`id`, `category_id`, `name`, `ordering`, `status`, `added_date`, `added_user_id`) VALUES
(14, 2, 'Bodysuits & Onesies', 1, 1, NOW(), 1),
(15, 2, 'Tops & T-Shirts', 2, 1, NOW(), 1),
(16, 2, 'Trousers & Leggings', 3, 1, NOW(), 1),
(17, 2, 'Dresses & Skirts', 4, 1, NOW(), 1),
(18, 2, 'Outfits & Sets', 5, 1, NOW(), 1),
(19, 2, 'Outerwear & Coats', 6, 1, NOW(), 1),
(20, 2, 'Sleepwear & Pajamas', 7, 1, NOW(), 1),
(21, 2, 'Baby Shoes & Socks', 8, 1, NOW(), 1),
(22, 2, 'Accessories, Hats & Bibs', 9, 1, NOW(), 1),
(23, 2, 'Baby Gear & Strollers', 10, 1, NOW(), 1);

-- Subcategory Language Strings for Baby (1: en, 2: ar, 3: fr)
INSERT INTO `psx_sub_category_language_strings` (`subcategory_id`, `language_id`, `key`, `value`, `added_date`, `added_user_id`) VALUES
(14, 1, 'Bodysuits & Onesies', 'Bodysuits & Onesies', NOW(), 1),
(14, 2, 'Bodysuits & Onesies', 'بودي وملابس داخلية للرضع', NOW(), 1),
(14, 3, 'Bodysuits & Onesies', 'Bodies & Grenouillères', NOW(), 1),

(15, 1, 'Tops & T-Shirts', 'Tops & T-Shirts', NOW(), 1),
(15, 2, 'Tops & T-Shirts', 'تيشيرتات وبلوزات', NOW(), 1),
(15, 3, 'Tops & T-Shirts', 'Hauts & T-shirts', NOW(), 1),

(16, 1, 'Trousers & Leggings', 'Trousers & Leggings', NOW(), 1),
(16, 2, 'Trousers & Leggings', 'سراويل وليقنز', NOW(), 1),
(16, 3, 'Trousers & Leggings', 'Pantalons & Leggings', NOW(), 1),

(17, 1, 'Dresses & Skirts', 'Dresses & Skirts', NOW(), 1),
(17, 2, 'Dresses & Skirts', 'فساتين وتنانير', NOW(), 1),
(17, 3, 'Dresses & Skirts', 'Robes & Jupes', NOW(), 1),

(18, 1, 'Outfits & Sets', 'Outfits & Sets', NOW(), 1),
(18, 2, 'Outfits & Sets', 'أطقم كاملة', NOW(), 1),
(18, 3, 'Outfits & Sets', 'Ensembles', NOW(), 1),

(19, 1, 'Outerwear & Coats', 'Outerwear & Coats', NOW(), 1),
(19, 2, 'Outerwear & Coats', 'معاطف وسترات', NOW(), 1),
(19, 3, 'Outerwear & Coats', 'Manteaux & Combinaisons', NOW(), 1),

(20, 1, 'Sleepwear & Pajamas', 'Sleepwear & Pajamas', NOW(), 1),
(20, 2, 'Sleepwear & Pajamas', 'بيجامات وأكياس نوم', NOW(), 1),
(20, 3, 'Sleepwear & Pajamas', 'Pyjamas & Gigoteuses', NOW(), 1),

(21, 1, 'Baby Shoes & Socks', 'Baby Shoes & Socks', NOW(), 1),
(21, 2, 'Baby Shoes & Socks', 'أحذية وجوارب الرضع', NOW(), 1),
(21, 3, 'Baby Shoes & Socks', 'Chaussures & Chaussettes', NOW(), 1),

(22, 1, 'Accessories, Hats & Bibs', 'Accessories, Hats & Bibs', NOW(), 1),
(22, 2, 'Accessories, Hats & Bibs', 'إكسسوارات وقبعات ومرايل', NOW(), 1),
(22, 3, 'Accessories, Hats & Bibs', 'Accessoires, Bonnets & Bavoirs', NOW(), 1),

(23, 1, 'Baby Gear & Strollers', 'Baby Gear & Strollers', NOW(), 1),
(23, 2, 'Baby Gear & Strollers', 'مستلزمات وعربات الأطفال', NOW(), 1),
(23, 3, 'Baby Gear & Strollers', 'Puériculture & Poussettes', NOW(), 1);

-- 4. Update any existing items to point to valid category and subcategory
UPDATE `psx_items` SET `category_id` = 1, `subcategory_id` = 1 WHERE `category_id` IS NOT NULL;

COMMIT;
SET FOREIGN_KEY_CHECKS = 1;
