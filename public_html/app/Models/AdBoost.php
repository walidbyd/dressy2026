<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Modules\Core\Entities\Vendor\Vendor;

class AdBoost extends Model
{
    protected $table = 'psx_ad_boosts';

    protected $fillable = [
        'user_id',
        'vendor_id',
        'target_type',
        'target_id',
        'plan_tier',
        'amount_paid_dzd',
        'starts_at',
        'expires_at',
    ];

    protected $casts = [
        'user_id' => 'integer',
        'vendor_id' => 'integer',
        'target_id' => 'integer',
        'amount_paid_dzd' => 'float',
        'starts_at' => 'datetime',
        'expires_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function vendor()
    {
        return $this->belongsTo(Vendor::class, 'vendor_id');
    }
}
