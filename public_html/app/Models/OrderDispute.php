<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Modules\Core\Entities\Vendor\Vendor;
use Modules\StoreFront\VendorPanel\Entities\Order;

class OrderDispute extends Model
{
    protected $table = 'psx_order_disputes';

    protected $fillable = [
        'order_id',
        'order_code',
        'buyer_user_id',
        'vendor_id',
        'seller_user_id',
        'dispute_type',
        'description',
        'status',
        'admin_note',
        'resolved_by',
        'resolved_at',
        'delivered_at',
    ];

    protected $casts = [
        'order_id' => 'integer',
        'buyer_user_id' => 'integer',
        'vendor_id' => 'integer',
        'seller_user_id' => 'integer',
        'resolved_by' => 'integer',
        'resolved_at' => 'datetime',
        'delivered_at' => 'datetime',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class, 'order_id');
    }

    public function buyer()
    {
        return $this->belongsTo(User::class, 'buyer_user_id');
    }

    public function seller()
    {
        return $this->belongsTo(User::class, 'seller_user_id');
    }

    public function vendor()
    {
        return $this->belongsTo(Vendor::class, 'vendor_id');
    }
}
