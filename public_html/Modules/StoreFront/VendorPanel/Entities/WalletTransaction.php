<?php

namespace Modules\StoreFront\VendorPanel\Entities;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class WalletTransaction extends Model
{
    use HasFactory;

    protected $table = 'psx_wallet_transactions';

    protected $fillable = [
        'id',
        'wallet_id',
        'user_id',
        'type',
        'source',
        'order_code',
        'amount',
        'gross_amount',
        'commission_amount',
        'balance_after',
        'reference_type',
        'reference_id',
        'note',
        'description',
        'added_user_id',
    ];

    protected $casts = [
        'amount' => 'float',
        'gross_amount' => 'float',
        'commission_amount' => 'float',
        'balance_after' => 'float',
    ];

    public function wallet()
    {
        return $this->belongsTo(Wallet::class, 'wallet_id', 'id');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'id');
    }

    public function author()
    {
        return $this->belongsTo(User::class, 'added_user_id', 'id');
    }

    public function addedUser()
    {
        return $this->belongsTo(User::class, 'added_user_id', 'id');
    }
}
