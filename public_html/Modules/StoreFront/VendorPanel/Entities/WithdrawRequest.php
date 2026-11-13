<?php

namespace Modules\StoreFront\VendorPanel\Entities;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class WithdrawRequest extends Model
{
    use HasFactory;

    protected $table = 'psx_withdraw_requests';

    protected $fillable = [
        'id',
        'wallet_id',
        'user_id',
        'amount',
        'status',
        'note',
        'admin_reference',
        'admin_note',
    ];

    protected $casts = [
        'amount' => 'float',
    ];

    public function wallet()
    {
        return $this->belongsTo(Wallet::class, 'wallet_id', 'id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'id');
    }

    public function vendor()
    {
        return $this->hasOneThrough(
            \Modules\Core\Entities\Vendor\Vendor::class,
            User::class,
            'id',
            'owner_user_id',
            'user_id',
            'id'
        );
    }
}
