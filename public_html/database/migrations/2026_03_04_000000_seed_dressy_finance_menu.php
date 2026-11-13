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
        // 1. Add admin columns to psx_withdraw_requests if not present
        if (Schema::hasTable('psx_withdraw_requests')) {
            Schema::table('psx_withdraw_requests', function (Blueprint $table) {
                if (!Schema::hasColumn('psx_withdraw_requests', 'admin_reference')) {
                    $table->string('admin_reference', 255)->nullable()->after('note');
                }
                if (!Schema::hasColumn('psx_withdraw_requests', 'admin_note')) {
                    $table->text('admin_note')->nullable()->after('admin_reference');
                }
            });
        }

        // 2. Insert or find sub_menu_group
        $subMenuGroup = DB::table('psx_core_sub_menu_groups')->where('sub_menu_lang_key', 'dressy_finance_group')->first();
        if (!$subMenuGroup) {
            $subMenuGroupId = DB::table('psx_core_sub_menu_groups')->insertGetId([
                'sub_menu_name' => 'dressy_finance',
                'sub_menu_desc' => 'Dressy Finance & Escrow',
                'icon_id' => '1',
                'sub_menu_lang_key' => 'dressy_finance_group',
                'ordering' => 90,
                'is_show_on_menu' => 1,
                'module_id' => null,
                'core_menu_group_id' => 1,
                'added_date' => now(),
                'added_user_id' => 1,
                'is_dropdown' => 1,
            ]);
        } else {
            $subMenuGroupId = $subMenuGroup->id;
        }

        // 3. Define the 4 modules
        $modules = [
            [
                'title' => 'c2c_escrow',
                'desc' => 'COD Escrow / Mark Paid',
                'lang_key' => 'dressy_escrow_module',
                'route_name' => 'admin.escrow.index',
                'ordering' => 1,
            ],
            [
                'title' => 'seller_wallets',
                'desc' => 'Seller Wallets',
                'lang_key' => 'dressy_wallets_module',
                'route_name' => 'admin.wallets.index',
                'ordering' => 2,
            ],
            [
                'title' => 'withdraw_requests',
                'desc' => 'Withdrawal Requests',
                'lang_key' => 'dressy_withdrawals_module',
                'route_name' => 'admin.withdrawals.index',
                'ordering' => 3,
            ],
            [
                'title' => 'c2c_commission',
                'desc' => 'Commission & Settings',
                'lang_key' => 'dressy_commission_module',
                'route_name' => 'admin.commission.index',
                'ordering' => 4,
            ],
        ];

        foreach ($modules as $mod) {
            // Find or create module
            $module = DB::table('psx_modules')->where('route_name', $mod['route_name'])->first();
            if (!$module) {
                $moduleId = DB::table('psx_modules')->insertGetId([
                    'title' => $mod['title'],
                    'lang_key' => $mod['lang_key'],
                    'added_date' => now(),
                    'added_user_id' => 1,
                    'sub_menu_id' => $subMenuGroupId,
                    'is_not_from_sidebar' => 0,
                    'status' => 1,
                    'route_name' => $mod['route_name'],
                ]);
            } else {
                $moduleId = $module->id;
                DB::table('psx_modules')->where('id', $moduleId)->update([
                    'sub_menu_id' => $subMenuGroupId,
                    'status' => 1,
                ]);
            }

            // Find or create core menu
            $coreMenu = DB::table('psx_core_menus')->where('module_id', $moduleId)->first();
            if (!$coreMenu) {
                $menuId = DB::table('psx_core_menus')->insertGetId([
                    'module_name' => $mod['title'],
                    'module_desc' => $mod['desc'],
                    'module_lang_key' => $mod['lang_key'],
                    'icon_id' => null,
                    'ordering' => $mod['ordering'],
                    'is_show_on_menu' => 1,
                    'module_id' => $moduleId,
                    'core_sub_menu_group_id' => $subMenuGroupId,
                    'added_date' => now(),
                    'added_user_id' => 1,
                ]);
            } else {
                $menuId = $coreMenu->id;
                DB::table('psx_core_menus')->where('id', $menuId)->update([
                    'core_sub_menu_group_id' => $subMenuGroupId,
                    'is_show_on_menu' => 1,
                ]);
            }

            // Update menu_id on module
            DB::table('psx_modules')->where('id', $moduleId)->update(['menu_id' => $menuId]);

            // Ensure role permission for Super Admin (role_id = 1)
            $perm = DB::table('psx_role_permissions')
                ->where('role_id', 1)
                ->where('module_id', $moduleId)
                ->first();

            if (!$perm) {
                DB::table('psx_role_permissions')->insert([
                    'role_id' => 1,
                    'module_id' => $moduleId,
                    'permission_id' => '1,2,3,4',
                    'added_date' => now(),
                    'added_user_id' => 1,
                ]);
            } else {
                DB::table('psx_role_permissions')
                    ->where('id', $perm->id)
                    ->update(['permission_id' => '1,2,3,4']);
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
        $modules = DB::table('psx_modules')->whereIn('route_name', [
            'admin.escrow.index',
            'admin.wallets.index',
            'admin.withdrawals.index',
            'admin.commission.index',
        ])->get();

        foreach ($modules as $mod) {
            DB::table('psx_role_permissions')->where('module_id', $mod->id)->delete();
            DB::table('psx_core_menus')->where('module_id', $mod->id)->delete();
            DB::table('psx_modules')->where('id', $mod->id)->delete();
        }

        DB::table('psx_core_sub_menu_groups')->where('sub_menu_lang_key', 'dressy_finance_group')->delete();
    }
};
