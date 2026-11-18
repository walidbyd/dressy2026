<?php

namespace App\Models\Chabit;

use Illuminate\Database\Eloquent\Model;

class ChabitMessage extends Model
{
    protected $table = 'chabit_messages';

    protected $fillable = [
        'thread_id',
        'sender_type',
        'body',
        'quick_replies',
        'metadata',
        'is_read',
    ];

    protected $casts = [
        'quick_replies' => 'array',
        'metadata' => 'array',
        'is_read' => 'boolean',
    ];

    public function thread()
    {
        return $this->belongsTo(ChabitThread::class, 'thread_id');
    }
}
