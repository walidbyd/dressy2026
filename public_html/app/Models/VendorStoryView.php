<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class VendorStoryView extends Model
{
    use HasFactory;

    protected $table = 'psx_vendor_story_views';

    public $timestamps = false;

    protected $fillable = [
        'story_id',
        'viewer_user_id',
        'viewed_at',
    ];

    protected $casts = [
        'viewed_at' => 'datetime',
    ];

    public function story()
    {
        return $this->belongsTo(VendorStory::class, 'story_id');
    }

    public function viewer()
    {
        return $this->belongsTo(User::class, 'viewer_user_id');
    }
}
