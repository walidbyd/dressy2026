<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AdSetting extends Model
{
    protected $table = 'psx_ad_settings';

    protected $fillable = [
        'is_enabled',
        'story_boost_enabled',
        'story_boost_price_dzd',
        'story_boost_title',
        'story_boost_description',
    ];

    protected $casts = [
        'is_enabled' => 'boolean',
        'story_boost_enabled' => 'boolean',
        'story_boost_price_dzd' => 'float',
    ];
}
