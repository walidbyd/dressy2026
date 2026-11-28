<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('psx_roulette_settings')) {
            Schema::create('psx_roulette_settings', function (Blueprint $table) {
                $table->id();
                $table->boolean('is_enabled')->default(true);
                $table->unsignedInteger('daily_limit')->default(0);
                $table->unsignedInteger('total_limit')->default(0);
                $table->json('slices')->nullable();
                $table->timestamps();
            });
        }

        if (DB::table('psx_roulette_settings')->count() === 0) {
            DB::table('psx_roulette_settings')->insert([
                'is_enabled' => true,
                'slices' => json_encode([
                    ['percent' => 5, 'label' => '-5%', 'weight' => 50, 'color' => '#3B82F6'],
                    ['percent' => 20, 'label' => '-20%', 'weight' => 0, 'color' => '#EC4899'],
                    ['percent' => 10, 'label' => '-10%', 'weight' => 50, 'color' => '#10B981'],
                    ['percent' => 50, 'label' => '-50%', 'weight' => 0, 'color' => '#F59E0B'],
                    ['percent' => 5, 'label' => '-5%', 'weight' => 0, 'color' => '#8B5CF6'],
                    ['percent' => 10, 'label' => '-10%', 'weight' => 0, 'color' => '#EF4444'],
                ]),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('psx_roulette_settings');
    }
};
