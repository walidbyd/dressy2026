<?php

namespace Modules\StoreFront\VendorPanel\Entities;

use App\Models\PsModel;
use App\Models\User;
use App\Traits\VendorAuthorizationTrait;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Modules\Core\Constants\Constants;
use Modules\Core\Entities\Vendor\Vendor;

class Order extends PsModel
{
    use HasFactory, VendorAuthorizationTrait;

    protected $fillable = ['id', 'user_id', 'vendor_id', 'order_date', 'total_price', 'total_amount', 'delivery_fee', 'order_status_id', 'order_code', 'is_payment_fail', 'yalidine_tracking', 'yalidine_parcel_id', 'yalidine_status', 'status_reason', 'is_wallet_credited', 'wallet_credited_at', 'added_date', 'added_user_id', 'updated_date', 'updated_user_id', 'updated_flag'];

    protected $table = 'psx_orders';

    const CREATED_AT = 'added_date';

    const UPDATED_AT = 'updated_date';

    const tableName = 'psx_orders';

    const userId = 'user_id';

    const id = 'id';

    const orderCode = 'order_code';

    const isPaymentFail = 'is_payment_fail';

    const yalidineTracking = 'yalidine_tracking';

    const yalidineParcelId = 'yalidine_parcel_id';

    const yalidineStatus = 'yalidine_status';

    const statusReason = 'status_reason';

    const isWalletCredited = 'is_wallet_credited';

    const walletCreditedAt = 'wallet_credited_at';

    const orderStatusId = 'order_status_id';

    const vendorId = 'vendor_id';

    const status = 'status';

    const addedDate = 'added_date';

    public function __construct()
    {
        $this->vendorModule = Constants::vendorOrderListModule;
    }

    protected static function newFactory()
    {
        // return \Modules\Core\Database\factories\CategoryFactory::new();
    }

    public function orderItems()
    {
        return $this->hasMany(OrderItem::class, 'order_id', 'id');
    }

    public function orderStatus()
    {
        return $this->belongsTo(OrderStatus::class, 'order_status_id', 'id');
    }

    public function shippingAndBilling()
    {
        return $this->hasOne(ShippingAndBilling::class, 'order_id', 'id');
    }

    public function vendorTransaction()
    {
        return $this->hasOne(VendorTransaction::class, 'order_id', 'id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'id');
    }

    public function buyer()
    {
        return $this->belongsTo(User::class, 'user_id', 'id');
    }

    public function seller()
    {
        return $this->hasOneThrough(
            User::class,
            Vendor::class,
            'id',
            'id',
            'vendor_id',
            'owner_user_id'
        );
    }

    public function owner()
    {
        return $this->belongsTo(User::class, 'added_user_id');
    }

    public function vendor()
    {
        return $this->belongsTo(Vendor::class, 'vendor_id');
    }

    public function editor()
    {
        return $this->belongsTo(User::class, 'updated_user_id');
    }
}
