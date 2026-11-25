<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('psx_orders')) {
            Schema::table('psx_orders', function (Blueprint $table) {
                if (!Schema::hasColumn('psx_orders', 'delivered_at')) {
                    $table->timestamp('delivered_at')->nullable();
                }
            });
        }

        if (!Schema::hasTable('psx_order_disputes')) {
            Schema::create('psx_order_disputes', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('order_id')->unique();
                $table->string('order_code', 64)->nullable();
                $table->unsignedBigInteger('buyer_user_id')->index();
                $table->unsignedBigInteger('vendor_id')->nullable()->index();
                $table->unsignedBigInteger('seller_user_id')->nullable()->index();
                $table->string('dispute_type', 48);
                $table->text('description');
                $table->string('status', 32)->default('open')->index();
                $table->text('admin_note')->nullable();
                $table->unsignedBigInteger('resolved_by')->nullable();
                $table->timestamp('resolved_at')->nullable();
                $table->timestamp('delivered_at')->nullable();
                $table->timestamps();
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('psx_order_disputes');

        if (Schema::hasTable('psx_orders')) {
            Schema::table('psx_orders', function (Blueprint $table) {
                if (Schema::hasColumn('psx_orders', 'delivered_at')) {
                    $table->dropColumn('delivered_at');
                }
            });
        }
    }
};
