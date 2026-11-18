<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('chabit_settings')) {
            Schema::create('chabit_settings', function (Blueprint $table) {
                $table->id();
                $table->text('gemini_api_key')->nullable();
                $table->string('gemini_model', 100)->default('gemini-3.6-flash');
                $table->boolean('is_enabled')->default(true);
                $table->boolean('auto_approve_items')->default(true);
                $table->unsignedInteger('auto_approve_confidence')->default(85);
                $table->longText('app_knowledge_base')->nullable();
                $table->timestamps();
            });

            DB::table('chabit_settings')->insert([
                'gemini_api_key' => null,
                'gemini_model' => 'gemini-3.6-flash',
                'is_enabled' => 1,
                'auto_approve_items' => 1,
                'auto_approve_confidence' => 85,
                'app_knowledge_base' => \App\Models\Chabit\ChabitSetting::defaultKnowledgeBase(),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        if (! Schema::hasTable('chabit_threads')) {
            Schema::create('chabit_threads', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id')->index();
                $table->unsignedBigInteger('order_id')->nullable()->index();
                $table->enum('thread_type', ['assistant', 'order_buyer', 'order_seller'])->default('assistant')->index();
                $table->string('language', 5)->nullable();
                $table->boolean('ai_paused')->default(false);
                $table->timestamp('last_message_at')->nullable()->index();
                $table->unsignedInteger('unread_admin_count')->default(0);
                $table->timestamps();
            });
        }

        if (! Schema::hasTable('chabit_messages')) {
            Schema::create('chabit_messages', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('thread_id')->index();
                $table->enum('sender_type', ['user', 'ai', 'admin', 'system'])->default('user');
                $table->text('body');
                $table->json('quick_replies')->nullable();
                $table->json('metadata')->nullable();
                $table->boolean('is_read')->default(false);
                $table->timestamps();
            });
        }

        if (Schema::hasTable('psx_items')) {
            Schema::table('psx_items', function (Blueprint $table) {
                if (! Schema::hasColumn('psx_items', 'ai_moderation_status')) {
                    $table->string('ai_moderation_status', 32)->nullable()->index();
                }
                if (! Schema::hasColumn('psx_items', 'ai_moderation_reason')) {
                    $table->text('ai_moderation_reason')->nullable();
                }
                if (! Schema::hasColumn('psx_items', 'ai_confidence')) {
                    $table->unsignedInteger('ai_confidence')->nullable();
                }
                if (! Schema::hasColumn('psx_items', 'approved_by_admin')) {
                    $table->boolean('approved_by_admin')->default(false);
                }
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('chabit_messages');
        Schema::dropIfExists('chabit_threads');
        Schema::dropIfExists('chabit_settings');

        if (Schema::hasTable('psx_items')) {
            Schema::table('psx_items', function (Blueprint $table) {
                foreach (['ai_moderation_status', 'ai_moderation_reason', 'ai_confidence', 'approved_by_admin'] as $col) {
                    if (Schema::hasColumn('psx_items', $col)) {
                        $table->dropColumn($col);
                    }
                }
            });
        }
    }
};
