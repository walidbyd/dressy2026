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
        if (!Schema::hasTable('psx_vendor_stories')) {
            Schema::create('psx_vendor_stories', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('user_id');
                $table->unsignedBigInteger('vendor_id')->nullable();
                $table->string('media_type', 16)->default('image'); // 'image' or 'video'
                $table->string('media_path', 255);
                $table->string('thumbnail_path', 255)->nullable();
                $table->string('caption', 500)->nullable();
                $table->unsignedBigInteger('item_id')->nullable();
                $table->string('filter_preset', 32)->default('original');
                $table->integer('views_count')->default(0);
                $table->integer('duration')->default(5); // seconds
                $table->timestamp('expires_at')->nullable();
                $table->timestamp('added_date')->useCurrent();
                $table->unsignedBigInteger('added_user_id')->nullable();
                $table->timestamps();

                $table->index(['user_id', 'expires_at'], 'idx_stories_user_expires');
                $table->index(['vendor_id', 'expires_at'], 'idx_stories_vendor_expires');
                $table->index('expires_at', 'idx_stories_expires_at');
            });
        } else {
            Schema::table('psx_vendor_stories', function (Blueprint $table) {
                if (!Schema::hasColumn('psx_vendor_stories', 'filter_preset')) {
                    $table->string('filter_preset', 32)->default('original')->after('item_id');
                }
                if (!Schema::hasColumn('psx_vendor_stories', 'item_id')) {
                    $table->unsignedBigInteger('item_id')->nullable()->after('caption');
                }
            });
        }

        if (!Schema::hasTable('psx_vendor_story_views')) {
            Schema::create('psx_vendor_story_views', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('story_id');
                $table->unsignedBigInteger('viewer_user_id');
                $table->timestamp('viewed_at')->useCurrent();

                $table->unique(['story_id', 'viewer_user_id'], 'idx_story_viewer_unique');
                $table->index('viewer_user_id', 'idx_views_viewer');
            });
        }
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::dropIfExists('psx_vendor_story_views');
        Schema::dropIfExists('psx_vendor_stories');
    }
};
