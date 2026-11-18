<?php

namespace App\Models\Chabit;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Modules\StoreFront\VendorPanel\Entities\Order;

class ChabitThread extends Model
{
    protected $table = 'chabit_threads';

    protected $fillable = [
        'user_id',
        'order_id',
        'thread_type',
        'language',
        'ai_paused',
        'last_message_at',
        'unread_admin_count',
    ];

    protected $casts = [
        'ai_paused' => 'boolean',
        'last_message_at' => 'datetime',
        'unread_admin_count' => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function order()
    {
        return $this->belongsTo(Order::class, 'order_id');
    }

    public function messages()
    {
        return $this->hasMany(ChabitMessage::class, 'thread_id')->orderBy('id', 'asc');
    }

    public function latestMessage()
    {
        return $this->hasOne(ChabitMessage::class, 'thread_id')->latestOfMany('id');
    }
}
