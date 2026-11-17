<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        $translations = [
            'app_name' => ['en' => 'Dressy', 'fr' => 'Dressy', 'ar' => 'Dressy'],
            'home_menu_drawer_home' => ['en' => 'Home', 'fr' => 'Accueil', 'ar' => 'الرئيسية'],
            'home__drawer_menu_home' => ['en' => 'Home', 'fr' => 'Accueil', 'ar' => 'الرئيسية'],
            'home_drawer_menu_home' => ['en' => 'Home', 'fr' => 'Accueil', 'ar' => 'الرئيسية'],
            'home__menu_drawer_home' => ['en' => 'Home', 'fr' => 'Accueil', 'ar' => 'الرئيسية'],
            'home_menu_drawer_category' => ['en' => 'Categories', 'fr' => 'Catégories', 'ar' => 'الفئات'],
            'home__menu_drawer_category' => ['en' => 'Categories', 'fr' => 'Catégories', 'ar' => 'الفئات'],
            'home__drawer_menu_category' => ['en' => 'Categories', 'fr' => 'Catégories', 'ar' => 'الفئات'],
            'home_menu_drawer_my_sales' => ['en' => 'My Sales', 'fr' => 'Mes ventes', 'ar' => 'مبيعاتي'],
            'home__menu_drawer_my_sales' => ['en' => 'My Sales', 'fr' => 'Mes ventes', 'ar' => 'مبيعاتي'],
            'home__drawer_menu_my_sales' => ['en' => 'My Sales', 'fr' => 'Mes ventes', 'ar' => 'مبيعاتي'],
            'home_menu_drawer_wallet' => ['en' => 'My Wallet', 'fr' => 'Mon portefeuille', 'ar' => 'محفظتي'],
            'home__menu_drawer_wallet' => ['en' => 'My Wallet', 'fr' => 'Mon portefeuille', 'ar' => 'محفظتي'],
            'home__drawer_menu_wallet' => ['en' => 'My Wallet', 'fr' => 'Mon portefeuille', 'ar' => 'محفظتي'],
            'home_menu_drawer_my_orders' => ['en' => 'My Orders', 'fr' => 'Mes commandes', 'ar' => 'طلباتي'],
            'home__menu_drawer_my_orders' => ['en' => 'My Orders', 'fr' => 'Mes commandes', 'ar' => 'طلباتي'],
            'home__drawer_menu_my_orders' => ['en' => 'My Orders', 'fr' => 'Mes commandes', 'ar' => 'طلباتي'],
            'vendor_reviews' => ['en' => 'Reviews', 'fr' => 'Avis', 'ar' => 'التقييمات'],
            'vendor_review' => ['en' => 'Reviews', 'fr' => 'Avis', 'ar' => 'التقييمات'],
            'vendor_rev' => ['en' => 'Reviews', 'fr' => 'Avis', 'ar' => 'التقييمات'],
        ];

        $langIds = [
            'en' => 1,
            'ar' => 2,
            'fr' => 4,
        ];

        // 1. Update app_name everywhere
        DB::table('psx_mobile_language_strings')
            ->where('key', 'app_name')
            ->update(['value' => 'Dressy', 'updated_date' => Carbon::now()]);

        // 2. Insert or update keys
        foreach ($translations as $key => $values) {
            foreach ($langIds as $langCode => $langId) {
                if (!isset($values[$langCode])) continue;
                $val = $values[$langCode];

                $existing = DB::table('psx_mobile_language_strings')
                    ->where('mobile_language_id', $langId)
                    ->where('key', $key)
                    ->first();

                if ($existing) {
                    DB::table('psx_mobile_language_strings')
                        ->where('id', $existing->id)
                        ->update(['value' => $val, 'updated_date' => Carbon::now()]);
                } else {
                    DB::table('psx_mobile_language_strings')->insert([
                        'mobile_language_id' => $langId,
                        'key' => $key,
                        'value' => $val,
                        'added_date' => Carbon::now(),
                        'added_user_id' => 1,
                        'updated_date' => Carbon::now(),
                    ]);
                }
            }
        }
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        // No-op rollback
    }
};
