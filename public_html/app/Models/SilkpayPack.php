<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SilkpayPack extends Model
{
    protected $table = 'psx_silkpay_packs';

    protected $fillable = ['amount_dzd', 'title', 'payment_url', 'is_active', 'sort_order'];

    protected $casts = [
        'amount_dzd' => 'float',
        'is_active' => 'boolean',
        'sort_order' => 'integer',
    ];
}
