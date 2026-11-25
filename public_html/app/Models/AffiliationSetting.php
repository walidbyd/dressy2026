<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AffiliationSetting extends Model
{
    protected $table = 'psx_affiliation_settings';

    protected $fillable = [
        'issuer_percentage',
        'receiver_percentage',
    ];

    protected $casts = [
        'issuer_percentage' => 'float',
        'receiver_percentage' => 'float',
    ];
}
