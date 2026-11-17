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
            if (!Schema::hasColumn('psx_orders', 'is_reviewed')) {
                $table->boolean('is_reviewed')->default(0)->after('order_status_id');
            }
            if (!Schema::hasColumn('psx_orders', 'review_rating')) {
                $table->decimal('review_rating', 3, 1)->nullable()->after('is_reviewed');
            }
            if (!Schema::hasColumn('psx_orders', 'review_id')) {
                $table->foreignId('review_id')->nullable()->after('review_rating');
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
            if (Schema::hasColumn('psx_orders', 'review_id')) {
                $table->dropColumn('review_id');
            }
            if (Schema::hasColumn('psx_orders', 'review_rating')) {
                $table->dropColumn('review_rating');
            }
            if (Schema::hasColumn('psx_orders', 'is_reviewed')) {
                $table->dropColumn('is_reviewed');
            }
        });
    }
};
