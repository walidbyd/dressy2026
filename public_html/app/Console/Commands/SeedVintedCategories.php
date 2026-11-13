<?php

namespace App\Console\Commands;

use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Modules\Core\Constants\Constants;
use Modules\Core\Http\Facades\PsCache;

class SeedVintedCategories extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'dressy:seed-vinted-categories {--force : Force execution without confirmation}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Replace all categories with Vinted-style 2-level taxonomy (Women & Baby only) with EN, FR, AR localization';

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $this->info('Starting Vinted 2-Level Category Taxonomy Seeding...');

        if (! $this->option('force') && ! $this->confirm('This will wipe all existing categories and subcategories and replace them with Women & Baby taxonomy. Continue?', true)) {
            $this->warn('Operation cancelled.');

            return 0;
        }

        try {
            DB::statement('SET FOREIGN_KEY_CHECKS=0;');

            $now = Carbon::now();

            // Find Super Admin user ID or fallback to 1
            $adminUser = DB::table('users')->where('email', 'biadwalid@gmail.com')->first();
            $adminId = $adminUser ? $adminUser->id : 1;

            // 1. Wipe existing categories, subcategories, language strings and subscriptions
            $this->line('Clearing existing categories, subcategories, and language strings...');
            DB::table('psx_category_language_strings')->delete();
            DB::statement('ALTER TABLE psx_category_language_strings AUTO_INCREMENT = 1;');
            DB::table('psx_sub_category_language_strings')->delete();
            DB::statement('ALTER TABLE psx_sub_category_language_strings AUTO_INCREMENT = 1;');
            DB::table('psx_subcat_subscribes')->delete();
            DB::table('psx_subcategories')->delete();
            DB::statement('ALTER TABLE psx_subcategories AUTO_INCREMENT = 1;');
            DB::table('psx_categories')->delete();
            DB::statement('ALTER TABLE psx_categories AUTO_INCREMENT = 1;');

            DB::beginTransaction();

            // Clean previous category images
            DB::table('psx_core_images')->whereIn('img_type', ['category-cover', 'category-icon', 'subcategory-cover', 'subcategory-icon'])->delete();

            // Verify or ensure Language IDs in psx_languages
            $enLang = DB::table('psx_languages')->where('symbol', 'en')->first();
            $arLang = DB::table('psx_languages')->where('symbol', 'ar')->first();
            $frLang = DB::table('psx_languages')->where('symbol', 'fr')->first();

            $enId = $enLang ? $enLang->id : 1;
            $arId = $arLang ? $arLang->id : 2;
            $frId = $frLang ? $frLang->id : 3;

            // 2. Define Category & Subcategory Taxonomy
            $taxonomy = [
                [
                    'name' => 'Women',
                    'ordering' => 1,
                    'cover' => '6556eef6ae7ca_.png',
                    'icon' => '6556eef709c2e_.png',
                    'translations' => [
                        'en' => 'Women',
                        'fr' => 'Femme',
                        'ar' => 'نساء',
                    ],
                    'subcategories' => [
                        ['name' => 'Dresses', 'ordering' => 1, 'translations' => ['en' => 'Dresses', 'fr' => 'Robes', 'ar' => 'فساتين']],
                        ['name' => 'Tops & T-Shirts', 'ordering' => 2, 'translations' => ['en' => 'Tops & T-Shirts', 'fr' => 'Hauts & T-shirts', 'ar' => 'بلوزات وتيشيرتات']],
                        ['name' => 'Sweaters & Cardigans', 'ordering' => 3, 'translations' => ['en' => 'Sweaters & Cardigans', 'fr' => 'Pulls & Gilets', 'ar' => 'كنزات وسترات صوفية']],
                        ['name' => 'Coats & Jackets', 'ordering' => 4, 'translations' => ['en' => 'Coats & Jackets', 'fr' => 'Manteaux & Vestes', 'ar' => 'معاطف وجاكيتات']],
                        ['name' => 'Jeans & Trousers', 'ordering' => 5, 'translations' => ['en' => 'Jeans & Trousers', 'fr' => 'Jeans & Pantalons', 'ar' => 'جينز وسراويل']],
                        ['name' => 'Skirts & Shorts', 'ordering' => 6, 'translations' => ['en' => 'Skirts & Shorts', 'fr' => 'Jupes & Shorts', 'ar' => 'تنانير وشورتات']],
                        ['name' => 'Suits & Blazers', 'ordering' => 7, 'translations' => ['en' => 'Suits & Blazers', 'fr' => 'Tailleurs & Blazers', 'ar' => 'بدل وبليزر']],
                        ['name' => 'Activewear & Loungewear', 'ordering' => 8, 'translations' => ['en' => 'Activewear & Loungewear', 'fr' => 'Sport & Détente', 'ar' => 'ملابس رياضية ومنزلية']],
                        ['name' => 'Swimwear & Lingerie', 'ordering' => 9, 'translations' => ['en' => 'Swimwear & Lingerie', 'fr' => 'Maillots de bain & Lingerie', 'ar' => 'ملابس سباحة ولانجري']],
                        ['name' => 'Traditional & Occasion Wear', 'ordering' => 10, 'translations' => ['en' => 'Traditional & Occasion Wear', 'fr' => 'Tenues traditionnelles & Soirée', 'ar' => 'أزياء تقليدية وسهرات']],
                        ['name' => 'Shoes', 'ordering' => 11, 'translations' => ['en' => 'Shoes', 'fr' => 'Chaussures', 'ar' => 'أحذية']],
                        ['name' => 'Bags & Backpacks', 'ordering' => 12, 'translations' => ['en' => 'Bags & Backpacks', 'fr' => 'Sacs & Sacs à dos', 'ar' => 'حقائب']],
                        ['name' => 'Accessories & Jewelry', 'ordering' => 13, 'translations' => ['en' => 'Accessories & Jewelry', 'fr' => 'Accessoires & Bijoux', 'ar' => 'إكسسوارات ومجوهرات']],
                    ],
                ],
                [
                    'name' => 'Baby',
                    'ordering' => 2,
                    'cover' => '6556ef8667151_.png',
                    'icon' => '6556ef86abdd1_.png',
                    'translations' => [
                        'en' => 'Baby',
                        'fr' => 'Bébé',
                        'ar' => 'أطفال رضع',
                    ],
                    'subcategories' => [
                        ['name' => 'Bodysuits & Onesies', 'ordering' => 1, 'translations' => ['en' => 'Bodysuits & Onesies', 'fr' => 'Bodies & Grenouillères', 'ar' => 'بودي وملابس داخلية للرضع']],
                        ['name' => 'Tops & T-Shirts', 'ordering' => 2, 'translations' => ['en' => 'Tops & T-Shirts', 'fr' => 'Hauts & T-shirts', 'ar' => 'تيشيرتات وبلوزات']],
                        ['name' => 'Trousers & Leggings', 'ordering' => 3, 'translations' => ['en' => 'Trousers & Leggings', 'fr' => 'Pantalons & Leggings', 'ar' => 'سراويل وليقنز']],
                        ['name' => 'Dresses & Skirts', 'ordering' => 4, 'translations' => ['en' => 'Dresses & Skirts', 'fr' => 'Robes & Jupes', 'ar' => 'فساتين وتنانير']],
                        ['name' => 'Outfits & Sets', 'ordering' => 5, 'translations' => ['en' => 'Outfits & Sets', 'fr' => 'Ensembles', 'ar' => 'أطقم كاملة']],
                        ['name' => 'Outerwear & Coats', 'ordering' => 6, 'translations' => ['en' => 'Outerwear & Coats', 'fr' => 'Manteaux & Combinaisons', 'ar' => 'معاطف وسترات']],
                        ['name' => 'Sleepwear & Pajamas', 'ordering' => 7, 'translations' => ['en' => 'Sleepwear & Pajamas', 'fr' => 'Pyjamas & Gigoteuses', 'ar' => 'بيجامات وأكياس نوم']],
                        ['name' => 'Baby Shoes & Socks', 'ordering' => 8, 'translations' => ['en' => 'Baby Shoes & Socks', 'fr' => 'Chaussures & Chaussettes', 'ar' => 'أحذية وجوارب الرضع']],
                        ['name' => 'Accessories, Hats & Bibs', 'ordering' => 9, 'translations' => ['en' => 'Accessories, Hats & Bibs', 'fr' => 'Accessoires, Bonnets & Bavoirs', 'ar' => 'إكسسوارات وقبعات ومرايل']],
                        ['name' => 'Baby Gear & Strollers', 'ordering' => 10, 'translations' => ['en' => 'Baby Gear & Strollers', 'fr' => 'Puériculture & Poussettes', 'ar' => 'مستلزمات وعربات الأطفال']],
                    ],
                ],
            ];

            // 3. Seed Categories and Subcategories
            foreach ($taxonomy as $catData) {
                $catId = DB::table('psx_categories')->insertGetId([
                    'name' => $catData['name'],
                    'ordering' => $catData['ordering'],
                    'status' => 1,
                    'added_date' => $now,
                    'added_user_id' => $adminId,
                ]);

                $this->info("Seeded Category [{$catId}]: {$catData['name']}");

                // Category language strings
                $catLangs = [
                    ['category_id' => $catId, 'language_id' => $enId, 'key' => $catData['name'], 'value' => $catData['translations']['en'], 'added_date' => $now, 'added_user_id' => $adminId],
                    ['category_id' => $catId, 'language_id' => $arId, 'key' => $catData['name'], 'value' => $catData['translations']['ar'], 'added_date' => $now, 'added_user_id' => $adminId],
                    ['category_id' => $catId, 'language_id' => $frId, 'key' => $catData['name'], 'value' => $catData['translations']['fr'], 'added_date' => $now, 'added_user_id' => $adminId],
                ];
                DB::table('psx_category_language_strings')->insert($catLangs);

                // Category Cover & Icon Images
                DB::table('psx_core_images')->insert([
                    ['img_parent_id' => $catId, 'img_type' => 'category-cover', 'img_path' => $catData['cover'], 'ordering' => 1],
                    ['img_parent_id' => $catId, 'img_type' => 'category-icon', 'img_path' => $catData['icon'], 'ordering' => 1],
                ]);

                // Subcategories
                foreach ($catData['subcategories'] as $subcatData) {
                    $subId = DB::table('psx_subcategories')->insertGetId([
                        'name' => $subcatData['name'],
                        'category_id' => $catId,
                        'ordering' => $subcatData['ordering'],
                        'status' => 1,
                        'added_date' => $now,
                        'added_user_id' => $adminId,
                    ]);

                    // Subcategory language strings
                    $subLangs = [
                        ['subcategory_id' => $subId, 'language_id' => $enId, 'key' => $subcatData['name'], 'value' => $subcatData['translations']['en'], 'added_date' => $now, 'added_user_id' => $adminId],
                        ['subcategory_id' => $subId, 'language_id' => $arId, 'key' => $subcatData['name'], 'value' => $subcatData['translations']['ar'], 'added_date' => $now, 'added_user_id' => $adminId],
                        ['subcategory_id' => $subId, 'language_id' => $frId, 'key' => $subcatData['name'], 'value' => $subcatData['translations']['fr'], 'added_date' => $now, 'added_user_id' => $adminId],
                    ];
                    DB::table('psx_sub_category_language_strings')->insert($subLangs);
                }

                $this->line("  -> Seeded " . count($catData['subcategories']) . " subcategories for {$catData['name']}");
            }

            // Update existing items to Women (first category) and Dresses (first subcategory) if any exist
            $firstCat = DB::table('psx_categories')->first();
            $firstSub = DB::table('psx_subcategories')->first();
            if ($firstCat && $firstSub) {
                DB::table('psx_items')->update([
                    'category_id' => $firstCat->id,
                    'subcategory_id' => $firstSub->id,
                ]);
            }

            DB::commit();
            DB::statement('SET FOREIGN_KEY_CHECKS=1;');

            // Clear cache
            try {
                PsCache::clear();
            } catch (\Throwable $_) {}

            $this->info('Successfully seeded Vinted 2-Level Category Taxonomy (Women & Baby only)!');

            return 0;

        } catch (\Throwable $e) {
            DB::rollBack();
            DB::statement('SET FOREIGN_KEY_CHECKS=1;');
            $this->error('Failed to seed categories: ' . $e->getMessage());

            return 1;
        }
    }
}
