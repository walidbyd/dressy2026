<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
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
            if (!Schema::hasColumn('psx_orders', 'yalidine_tracking')) {
                $table->string('yalidine_tracking')->nullable()->after('is_payment_fail');
            }
            if (!Schema::hasColumn('psx_orders', 'yalidine_parcel_id')) {
                $table->string('yalidine_parcel_id')->nullable()->after('yalidine_tracking');
            }
            if (!Schema::hasColumn('psx_orders', 'yalidine_status')) {
                $table->string('yalidine_status')->nullable()->after('yalidine_parcel_id');
            }
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('psx_orders', function (Blueprint $table) {
            $columns = [];
            if (Schema::hasColumn('psx_orders', 'yalidine_tracking')) {
                $columns[] = 'yalidine_tracking';
            }
            if (Schema::hasColumn('psx_orders', 'yalidine_parcel_id')) {
                $columns[] = 'yalidine_parcel_id';
            }
            if (Schema::hasColumn('psx_orders', 'yalidine_status')) {
                $columns[] = 'yalidine_status';
            }
            if (!empty($columns)) {
                $table->dropColumn($columns);
            }
        });
    }
};
