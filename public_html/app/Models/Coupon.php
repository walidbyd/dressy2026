<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Coupon extends Model
{
    protected $table = 'psx_coupons';

    protected $fillable = [
        'code',
        'discount_type',
        'discount_value',
        'min_order_amount',
        'max_uses',
        'used_count',
        'max_uses_per_user',
        'user_id',
        'target_type',
        'target_group',
        'target_user_ids',
        'source',
        'is_active',
        'expires_at',
    ];

    protected $casts = [
        'discount_value' => 'float',
        'min_order_amount' => 'float',
        'max_uses' => 'integer',
        'used_count' => 'integer',
        'max_uses_per_user' => 'integer',
        'user_id' => 'integer',
        'target_user_ids' => 'array',
        'is_active' => 'boolean',
        'expires_at' => 'datetime',
    ];

    public function usages()
    {
        return $this->hasMany(CouponUsage::class, 'coupon_id');
    }

    public function user()
    {
        return $this->belongsTo(\App\Models\User::class, 'user_id');
    }
}
