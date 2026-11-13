<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Carbon\Carbon;

class DressyCleanProduction extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'dressy:clean-production {--force : Force the operation without confirmation}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Clean demo data, localize to Algeria (58 Wilayas & DZD currency), and enforce COD-only payments';

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $this->info('Starting Dressy C2C Production Cleanup & Algerian Localization...');

        if (!$this->option('force') && !$this->confirm('This will wipe all demo users, items, and foreign cities, keeping ONLY biadwalid@gmail.com and seeding 58 Algerian Wilayas. Do you wish to continue?', true)) {
            $this->warn('Operation cancelled.');
            return 0;
        }

        try {
            DB::statement('SET FOREIGN_KEY_CHECKS=0;');
            DB::beginTransaction();

            $now = Carbon::now()->toDateTimeString();

            // 1. Verify Super Admin biadwalid@gmail.com
            $adminUser = DB::table('users')->where('email', 'biadwalid@gmail.com')->first();
            if (!$adminUser) {
                $this->error('Super Admin biadwalid@gmail.com not found! Aborting.');
                DB::rollBack();
                DB::statement('SET FOREIGN_KEY_CHECKS=1;');
                return 1;
            }

            $adminId = $adminUser->id;
            $this->line("Preserving Super Admin: {$adminUser->name} ({$adminUser->email}), ID: {$adminId}");

            // Ensure Super Admin privileges
            DB::table('users')->where('id', $adminId)->update([
                'role_id' => '1',
                'user_is_sys_admin' => 1,
                'status' => 1,
                'is_banned' => 0,
            ]);

            // 2. Delete Demo Users (keep only adminId)
            $deletedUsers = DB::table('users')->where('id', '!=', $adminId)->delete();
            $this->info("Removed {$deletedUsers} demo users from 'users' table.");

            // 3. Clean Dependent Tables for Deleted Users
            $userScopedTables = [
                'psx_user_infos',
                'psx_user_address_information',
                'psx_user_addresses',
                'psx_user_access_api_tokens',
                'psx_user_permissions',
                'psx_push_notification_tokens',
                'psx_push_notification_users',
                'psx_blue_mark_users',
                'psx_vendor_user_permissions',
            ];

            foreach ($userScopedTables as $tbl) {
                if (Schema::hasTable($tbl)) {
                    DB::table($tbl)->where('user_id', '!=', $adminId)->delete();
                }
            }

            if (Schema::hasTable('personal_access_tokens')) {
                DB::table('personal_access_tokens')->where('tokenable_id', '!=', $adminId)->delete();
            }

            // 4. Truncate demo activities / user actions
            $truncateTables = [
                'psx_user_boughts',
                'psx_follow_users',
                'psx_block_users',
                'psx_favourites',
                'psx_ratings',
                'psx_chat_histories',
                'psx_chat_notis',
                'psx_search_histories',
                'psx_carts',
                'psx_cart_items',
                'psx_touches',
                'psx_paid_item_histories',
                'psx_package_bought_transactions',
                'psx_subscription_bought_transactions',
                'psx_transaction_counts',
                'psx_transaction_details',
                'psx_transaction_headers',
                'psx_orders',
                'psx_order_items',
                'psx_shipping_and_billings',
                'psx_vendor_transactions',
                'psx_vendor_applications',
                'psx_items',
                'psx_item_infos',
                'psx_item_reports',
                'psx_wallet_transactions',
                'psx_withdraw_requests',
            ];

            foreach ($truncateTables as $tbl) {
                if (Schema::hasTable($tbl)) {
                    DB::table($tbl)->delete();
                }
            }
            $this->info("Cleared demo transactions, orders, items, and chats.");

            // 5. Clean item images from psx_core_images (preserving branding & category icons)
            if (Schema::hasTable('psx_core_images')) {
                $deletedImages = DB::table('psx_core_images')
                    ->whereIn('img_type', ['item', 'item-video', 'item-video-icon'])
                    ->delete();
                $this->info("Removed {$deletedImages} item images from 'psx_core_images'.");
            }

            // 6. Vendor Cleanup (Keep admin vendor, remove demo vendors)
            if (Schema::hasTable('psx_vendors')) {
                $adminVendor = DB::table('psx_vendors')->where('owner_user_id', $adminId)->first();
                if (!$adminVendor) {
                    // Create default vendor for admin if missing
                    $vendorId = DB::table('psx_vendors')->insertGetId([
                        'name' => 'Dressy Store',
                        'phone' => $adminUser->user_phone ?? '0550000000',
                        'email' => $adminUser->email,
                        'address' => 'Alger, Algérie',
                        'description' => 'Dressy Official Store',
                        'status' => '2', // Approved
                        'currency_id' => '1',
                        'owner_user_id' => $adminId,
                        'is_unlimited' => 1,
                        'added_date' => $now,
                        'added_user_id' => $adminId,
                    ]);
                } else {
                    $vendorId = $adminVendor->id;
                    DB::table('psx_vendors')->where('id', $vendorId)->update([
                        'status' => '2',
                        'owner_user_id' => $adminId,
                        'updated_date' => $now,
                    ]);
                }

                DB::table('psx_vendors')->where('id', '!=', $vendorId)->delete();

                if (Schema::hasTable('psx_vendor_branches')) {
                    DB::table('psx_vendor_branches')->where('vendor_id', '!=', $vendorId)->delete();
                }
                if (Schema::hasTable('psx_vendor_infos')) {
                    DB::table('psx_vendor_infos')->where('vendor_id', '!=', $vendorId)->delete();
                }
                if (Schema::hasTable('psx_vendor_delivery_settings')) {
                    DB::table('psx_vendor_delivery_settings')->where('vendor_id', '!=', $vendorId)->delete();
                }
            } else {
                $vendorId = 1;
            }

            // 7. Initialize Admin Wallet (0.00 DZD)
            if (Schema::hasTable('psx_wallets')) {
                DB::table('psx_wallets')->where('user_id', '!=', $adminId)->delete();
                $existingWallet = DB::table('psx_wallets')->where('user_id', $adminId)->first();
                if ($existingWallet) {
                    DB::table('psx_wallets')->where('id', $existingWallet->id)->update([
                        'vendor_id' => $vendorId,
                        'balance' => 0.00,
                        'currency_code' => 'DZD',
                        'updated_at' => $now,
                    ]);
                } else {
                    DB::table('psx_wallets')->insert([
                        'user_id' => $adminId,
                        'vendor_id' => $vendorId,
                        'balance' => 0.00,
                        'currency_code' => 'DZD',
                        'created_at' => $now,
                        'updated_at' => $now,
                    ]);
                }
                $this->info("Initialized Admin Wallet (ID: {$adminId}) with 0.00 DZD.");
            }

            // 8. Currency Configuration: Enforce DZD only
            if (Schema::hasTable('psx_currencies')) {
                DB::table('psx_currencies')->update(['status' => 0, 'is_default' => 0]);
                
                $dzdCurrency = DB::table('psx_currencies')->where('currency_short_form', 'DZD')->first();
                if ($dzdCurrency) {
                    $currencyId = $dzdCurrency->id;
                    DB::table('psx_currencies')->where('id', $currencyId)->update([
                        'currency_symbol' => 'DA',
                        'status' => 1,
                        'is_default' => 1,
                        'updated_date' => $now,
                        'updated_user_id' => $adminId,
                    ]);
                } else {
                    $currencyId = DB::table('psx_currencies')->insertGetId([
                        'currency_symbol' => 'DA',
                        'currency_short_form' => 'DZD',
                        'status' => 1,
                        'is_default' => 1,
                        'added_date' => $now,
                        'added_user_id' => $adminId,
                    ]);
                }

                // Update vendor currency
                if (Schema::hasTable('psx_vendors')) {
                    DB::table('psx_vendors')->where('id', $vendorId)->update(['currency_id' => $currencyId]);
                }
            }

            if (Schema::hasTable('psx_available_currencies')) {
                DB::table('psx_available_currencies')->update(['status' => 0, 'is_default' => 0]);
                DB::table('psx_available_currencies')->where('id', 129)->orWhere('currency_short_form', 'DZD')->update([
                    'status' => 1,
                    'is_default' => 1,
                    'updated_date' => $now,
                    'updated_user_id' => $adminId,
                ]);
            }
            $this->info("Set DZD (DA) as the sole active and default currency.");

            // 9. Payment Gateways: Enforce COD Only (payment00009)
            if (Schema::hasTable('psx_payments')) {
                DB::table('psx_payments')->where('id', '!=', 'payment00009')->update(['status' => 0]);
                DB::table('psx_payments')->where('id', 'payment00009')->update([
                    'status' => 1,
                    'updated_date' => $now,
                    'updated_user_id' => $adminId,
                ]);
            }

            if (Schema::hasTable('psx_vendor_payments')) {
                DB::table('psx_vendor_payments')->where('vendor_id', '!=', $vendorId)->delete();
                DB::table('psx_vendor_payments')->where('vendor_id', $vendorId)->where('payment_id', '!=', 'payment00009')->update(['status' => 0]);
                
                $codVendorPayment = DB::table('psx_vendor_payments')->where('vendor_id', $vendorId)->where('payment_id', 'payment00009')->first();
                if ($codVendorPayment) {
                    DB::table('psx_vendor_payments')->where('id', $codVendorPayment->id)->update(['status' => 1, 'updated_date' => $now]);
                } else {
                    DB::table('psx_vendor_payments')->insert([
                        'vendor_id' => $vendorId,
                        'payment_id' => 'payment00009',
                        'status' => 1,
                        'added_date' => $now,
                        'added_user_id' => $adminId,
                    ]);
                }
            }
            $this->info("Enforced COD (payment00009) as the ONLY active payment gateway.");

            // 10. Algerian Localization: Seed all 58 Wilayas
            if (Schema::hasTable('psx_location_townships')) {
                DB::table('psx_location_townships')->delete();
            }

            if (Schema::hasTable('psx_location_cities')) {
                DB::table('psx_location_cities')->delete();

                $wilayas = [
                    ['id' => 1, 'name' => 'Adrar', 'lat' => '27.8742', 'lng' => '-0.2939'],
                    ['id' => 2, 'name' => 'Chlef', 'lat' => '36.1652', 'lng' => '1.3345'],
                    ['id' => 3, 'name' => 'Laghouat', 'lat' => '33.8000', 'lng' => '2.8651'],
                    ['id' => 4, 'name' => 'Oum El Bouaghi', 'lat' => '35.8755', 'lng' => '7.1135'],
                    ['id' => 5, 'name' => 'Batna', 'lat' => '35.5558', 'lng' => '6.1741'],
                    ['id' => 6, 'name' => 'Béjaïa', 'lat' => '36.7509', 'lng' => '5.0567'],
                    ['id' => 7, 'name' => 'Biskra', 'lat' => '34.8504', 'lng' => '5.7281'],
                    ['id' => 8, 'name' => 'Béchar', 'lat' => '31.6167', 'lng' => '-2.2167'],
                    ['id' => 9, 'name' => 'Blida', 'lat' => '36.4700', 'lng' => '2.8277'],
                    ['id' => 10, 'name' => 'Bouira', 'lat' => '36.3749', 'lng' => '3.9020'],
                    ['id' => 11, 'name' => 'Tamanrasset', 'lat' => '22.7850', 'lng' => '5.5228'],
                    ['id' => 12, 'name' => 'Tébessa', 'lat' => '35.4042', 'lng' => '8.1242'],
                    ['id' => 13, 'name' => 'Tlemcen', 'lat' => '34.8783', 'lng' => '-1.3150'],
                    ['id' => 14, 'name' => 'Tiaret', 'lat' => '35.3710', 'lng' => '1.3170'],
                    ['id' => 15, 'name' => 'Tizi Ouzou', 'lat' => '36.7118', 'lng' => '4.0459'],
                    ['id' => 16, 'name' => 'Alger', 'lat' => '36.7538', 'lng' => '3.0588'],
                    ['id' => 17, 'name' => 'Djelfa', 'lat' => '34.6728', 'lng' => '3.2630'],
                    ['id' => 18, 'name' => 'Jijel', 'lat' => '36.8206', 'lng' => '5.7667'],
                    ['id' => 19, 'name' => 'Sétif', 'lat' => '36.1911', 'lng' => '5.4137'],
                    ['id' => 20, 'name' => 'Saïda', 'lat' => '34.8303', 'lng' => '0.1517'],
                    ['id' => 21, 'name' => 'Skikda', 'lat' => '36.8762', 'lng' => '6.9092'],
                    ['id' => 22, 'name' => 'Sidi Bel Abbès', 'lat' => '35.1899', 'lng' => '-0.6309'],
                    ['id' => 23, 'name' => 'Annaba', 'lat' => '36.9000', 'lng' => '7.7667'],
                    ['id' => 24, 'name' => 'Guelma', 'lat' => '36.4621', 'lng' => '7.4261'],
                    ['id' => 25, 'name' => 'Constantine', 'lat' => '36.3650', 'lng' => '6.6147'],
                    ['id' => 26, 'name' => 'Médéa', 'lat' => '36.2642', 'lng' => '2.7539'],
                    ['id' => 27, 'name' => 'Mostaganem', 'lat' => '35.9312', 'lng' => '0.0892'],
                    ['id' => 28, 'name' => "M'Sila", 'lat' => '35.7058', 'lng' => '4.5419'],
                    ['id' => 29, 'name' => 'Mascara', 'lat' => '35.3966', 'lng' => '0.1403'],
                    ['id' => 30, 'name' => 'Ouargla', 'lat' => '31.9493', 'lng' => '5.3250'],
                    ['id' => 31, 'name' => 'Oran', 'lat' => '35.6987', 'lng' => '-0.6349'],
                    ['id' => 32, 'name' => 'El Bayadh', 'lat' => '33.6832', 'lng' => '1.0193'],
                    ['id' => 33, 'name' => 'Illizi', 'lat' => '26.4833', 'lng' => '8.4667'],
                    ['id' => 34, 'name' => 'Bordj Bou Arreridj', 'lat' => '36.0731', 'lng' => '4.7611'],
                    ['id' => 35, 'name' => 'Boumerdès', 'lat' => '36.7599', 'lng' => '3.4728'],
                    ['id' => 36, 'name' => 'El Tarf', 'lat' => '36.7672', 'lng' => '8.3138'],
                    ['id' => 37, 'name' => 'Tindouf', 'lat' => '27.6711', 'lng' => '-8.1474'],
                    ['id' => 38, 'name' => 'Tissemsilt', 'lat' => '35.6072', 'lng' => '1.8108'],
                    ['id' => 39, 'name' => 'El Oued', 'lat' => '33.3683', 'lng' => '6.8674'],
                    ['id' => 40, 'name' => 'Khenchela', 'lat' => '35.4358', 'lng' => '7.1433'],
                    ['id' => 41, 'name' => 'Souk Ahras', 'lat' => '36.2864', 'lng' => '7.9511'],
                    ['id' => 42, 'name' => 'Tipaza', 'lat' => '36.5897', 'lng' => '2.4475'],
                    ['id' => 43, 'name' => 'Mila', 'lat' => '36.4503', 'lng' => '6.2644'],
                    ['id' => 44, 'name' => 'Aïn Defla', 'lat' => '36.2641', 'lng' => '1.9679'],
                    ['id' => 45, 'name' => 'Naâma', 'lat' => '33.2667', 'lng' => '-0.3167'],
                    ['id' => 46, 'name' => 'Aïn Témouchent', 'lat' => '35.2975', 'lng' => '-1.1404'],
                    ['id' => 47, 'name' => 'Ghardaïa', 'lat' => '32.4909', 'lng' => '3.6735'],
                    ['id' => 48, 'name' => 'Relizane', 'lat' => '35.7373', 'lng' => '0.5558'],
                    ['id' => 49, 'name' => 'Timimoun', 'lat' => '29.2639', 'lng' => '0.2310'],
                    ['id' => 50, 'name' => 'Bordj Badji Mokhtar', 'lat' => '21.3283', 'lng' => '0.9547'],
                    ['id' => 51, 'name' => 'Ouled Djellal', 'lat' => '34.4333', 'lng' => '5.0667'],
                    ['id' => 52, 'name' => 'Béni Abbès', 'lat' => '30.0833', 'lng' => '-2.1667'],
                    ['id' => 53, 'name' => 'In Salah', 'lat' => '27.1936', 'lng' => '2.4608'],
                    ['id' => 54, 'name' => 'In Guezzam', 'lat' => '19.5686', 'lng' => '5.7694'],
                    ['id' => 55, 'name' => 'Touggourt', 'lat' => '33.1064', 'lng' => '6.0594'],
                    ['id' => 56, 'name' => 'Djanet', 'lat' => '24.5531', 'lng' => '9.4858'],
                    ['id' => 57, 'name' => "El M'Ghair", 'lat' => '33.9500', 'lng' => '5.9167'],
                    ['id' => 58, 'name' => 'El Meniaa', 'lat' => '30.5833', 'lng' => '2.8833'],
                ];

                $insertData = [];
                foreach ($wilayas as $w) {
                    $insertData[] = [
                        'id' => $w['id'],
                        'name' => sprintf('%02d - %s', $w['id'], $w['name']),
                        'lat' => $w['lat'],
                        'lng' => $w['lng'],
                        'ordering' => $w['id'],
                        'status' => 1,
                        'description' => "Wilaya de {$w['name']}",
                        'touch_count' => 0,
                        'is_featured' => 0,
                        'featured_date' => null,
                        'added_date' => $now,
                        'added_user_id' => $adminId,
                        'updated_date' => $now,
                        'updated_user_id' => $adminId,
                        'updated_flag' => null,
                    ];
                }

                DB::table('psx_location_cities')->insert($insertData);
                $this->info("Seeded all 58 Algerian Wilayas in 'psx_location_cities' (Adrar 01 to El Meniaa 58).");
            }

            if (DB::transactionLevel() > 0) {
                DB::commit();
            }
            DB::statement('SET FOREIGN_KEY_CHECKS=1;');

            $this->info('Dressy C2C Production Cleanup & Algerian Localization completed successfully!');
            return 0;

        } catch (\Exception $e) {
            if (DB::transactionLevel() > 0) {
                DB::rollBack();
            }
            DB::statement('SET FOREIGN_KEY_CHECKS=1;');
            $this->error('Production cleanup failed: ' . $e->getMessage());
            $this->error($e->getTraceAsString());
            return 1;
        }
    }
}
