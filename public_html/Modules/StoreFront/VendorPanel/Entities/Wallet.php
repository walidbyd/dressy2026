<?php

namespace Modules\StoreFront\VendorPanel\Entities;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Modules\Core\Entities\Vendor\Vendor;

class Wallet extends Model
{
    use HasFactory;

    protected $table = 'psx_wallets';

    protected $fillable = [
        'id',
        'user_id',
        'vendor_id',
        'balance',
        'currency_code',
    ];

    protected $casts = [
        'balance' => 'float',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id', 'id');
    }

    public function vendor()
    {
        return $this->belongsTo(Vendor::class, 'vendor_id', 'id');
    }

    public function transactions()
    {
        return $this->hasMany(WalletTransaction::class, 'wallet_id', 'id')->latest();
    }
}
