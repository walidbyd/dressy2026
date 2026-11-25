<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SilkpaySetting extends Model
{
    protected $table = 'psx_silkpay_settings';

    protected $fillable = ['webhook_secret', 'api_key', 'is_active'];

    protected $casts = ['is_active' => 'boolean'];
}
