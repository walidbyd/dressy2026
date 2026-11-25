<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Modules\StoreFront\VendorPanel\Entities\Order;

class AffiliationReferral extends Model
{
    protected $table = 'psx_affiliation_referrals';

    protected $fillable = [
        'affiliation_code_id',
        'issuer_user_id',
        'receiver_user_id',
        'order_id',
        'order_code',
        'receiver_discount_percent',
        'receiver_discount_amount',
        'issuer_commission_percent',
        'issuer_commission_amount',
        'is_credited',
        'credited_at',
    ];

    protected $casts = [
        'affiliation_code_id' => 'integer',
        'issuer_user_id' => 'integer',
        'receiver_user_id' => 'integer',
        'order_id' => 'integer',
        'receiver_discount_percent' => 'float',
        'receiver_discount_amount' => 'float',
        'issuer_commission_percent' => 'float',
        'issuer_commission_amount' => 'float',
        'is_credited' => 'boolean',
        'credited_at' => 'datetime',
    ];

    public function affiliationCode()
    {
        return $this->belongsTo(AffiliationCode::class, 'affiliation_code_id');
    }

    public function issuer()
    {
        return $this->belongsTo(User::class, 'issuer_user_id');
    }

    public function receiver()
    {
        return $this->belongsTo(User::class, 'receiver_user_id');
    }

    public function order()
    {
        return $this->belongsTo(Order::class, 'order_id');
    }
}
