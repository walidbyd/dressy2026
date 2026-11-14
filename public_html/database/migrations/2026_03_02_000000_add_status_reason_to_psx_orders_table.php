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
        Schema::table('psx_orders', function (Blueprint $table) {
            if (!Schema::hasColumn('psx_orders', 'status_reason')) {
                $table->text('status_reason')->nullable()->after('yalidine_status');
            }
        });

        // Ensure "Returned" status (id = 6) and "Cancelled" status (id = 5) are seeded in psx_order_statuses
        try {
            $vendorIds = DB::table('psx_order_statuses')->select('vendor_id')->distinct()->pluck('vendor_id');
            if ($vendorIds->isEmpty()) {
                $vendorIds = collect([1]);
            }

            foreach ($vendorIds as $vendorId) {
                // Ensure Cancelled (5)
                $hasCancelled = DB::table('psx_order_statuses')
                    ->where('id', 5)
                    ->where('vendor_id', $vendorId)
                    ->exists();

                if (!$hasCancelled) {
                    DB::table('psx_order_statuses')->insert([
                        'id' => 5,
                        'name' => 'Cancelled',
                        'description' => 'Cancelled',
                        'colour' => '#EF4444',
                        'vendor_id' => $vendorId,
                        'status' => 1,
                        'is_ps_default' => 1,
                        'added_date' => now(),
                        'added_user_id' => 1,
                    ]);
                }

                // Ensure Returned (6)
                $hasReturned = DB::table('psx_order_statuses')
                    ->where('id', 6)
                    ->where('vendor_id', $vendorId)
                    ->exists();

                if (!$hasReturned) {
                    DB::table('psx_order_statuses')->insert([
                        'id' => 6,
                        'name' => 'Returned',
                        'description' => 'Returned',
                        'colour' => '#6B7280',
                        'vendor_id' => $vendorId,
                        'status' => 1,
                        'is_ps_default' => 1,
                        'added_date' => now(),
                        'added_user_id' => 1,
                    ]);
                }
            }
        } catch (\Throwable $e) {
            // Log or ignore if table is unavailable
        }
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('psx_orders', function (Blueprint $table) {
            if (Schema::hasColumn('psx_orders', 'status_reason')) {
                $table->dropColumn('status_reason');
            }
        });
    }
};
