<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        if (Schema::hasTable('psx_chat_histories')) {
            Schema::table('psx_chat_histories', function (Blueprint $table) {
                if (!Schema::hasColumn('psx_chat_histories', 'order_id')) {
                    $table->unsignedBigInteger('order_id')->nullable()->after('seller_user_id');
                }
                if (!Schema::hasColumn('psx_chat_histories', 'order_code')) {
                    $table->string('order_code', 50)->nullable()->after('order_id');
                }
                if (!Schema::hasColumn('psx_chat_histories', 'action_status')) {
                    $table->string('action_status', 20)->nullable()->default('none')->after('order_code');
                }
            });
        }

        if (Schema::hasTable('psx_chat_notis')) {
            Schema::table('psx_chat_notis', function (Blueprint $table) {
                if (!Schema::hasColumn('psx_chat_notis', 'order_id')) {
                    $table->unsignedBigInteger('order_id')->nullable()->after('seller_user_id');
                }
                if (!Schema::hasColumn('psx_chat_notis', 'order_code')) {
                    $table->string('order_code', 50)->nullable()->after('order_id');
                }
                if (!Schema::hasColumn('psx_chat_notis', 'message_type')) {
                    $table->string('message_type', 50)->nullable()->after('order_code');
                }
                if (!Schema::hasColumn('psx_chat_notis', 'action_status')) {
                    $table->string('action_status', 20)->nullable()->default('none')->after('message_type');
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('psx_chat_histories')) {
            Schema::table('psx_chat_histories', function (Blueprint $table) {
                $columns = [];
                if (Schema::hasColumn('psx_chat_histories', 'order_id')) {
                    $columns[] = 'order_id';
                }
                if (Schema::hasColumn('psx_chat_histories', 'order_code')) {
                    $columns[] = 'order_code';
                }
                if (Schema::hasColumn('psx_chat_histories', 'action_status')) {
                    $columns[] = 'action_status';
                }
                if (!empty($columns)) {
                    $table->dropColumn($columns);
                }
            });
        }

        if (Schema::hasTable('psx_chat_notis')) {
            Schema::table('psx_chat_notis', function (Blueprint $table) {
                $columns = [];
                if (Schema::hasColumn('psx_chat_notis', 'order_id')) {
                    $columns[] = 'order_id';
                }
                if (Schema::hasColumn('psx_chat_notis', 'order_code')) {
                    $columns[] = 'order_code';
                }
                if (Schema::hasColumn('psx_chat_notis', 'message_type')) {
                    $columns[] = 'message_type';
                }
                if (Schema::hasColumn('psx_chat_notis', 'action_status')) {
                    $columns[] = 'action_status';
                }
                if (!empty($columns)) {
                    $table->dropColumn($columns);
                }
            });
        }
    }
};
