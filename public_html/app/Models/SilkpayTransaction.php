<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SilkpayTransaction extends Model
{
    protected $table = 'psx_silkpay_transactions';

    protected $fillable = [
        'user_id',
        'pack_id',
        'reference',
        'amount_dzd',
        'payment_url',
        'status',
        'gateway_tx_id',
        'webhook_payload',
        'credited_at',
    ];

    protected $casts = [
        'user_id' => 'integer',
        'pack_id' => 'integer',
        'amount_dzd' => 'float',
        'webhook_payload' => 'array',
        'credited_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function pack()
    {
        return $this->belongsTo(SilkpayPack::class, 'pack_id');
    }
}
