<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AdPlan extends Model
{
    protected $table = 'psx_ad_plans';

    protected $fillable = [
        'tier',
        'duration_days',
        'title',
        'description',
        'price_dzd',
        'is_active',
        'sort_order',
    ];

    protected $casts = [
        'duration_days' => 'integer',
        'price_dzd' => 'float',
        'is_active' => 'boolean',
        'sort_order' => 'integer',
    ];
}
