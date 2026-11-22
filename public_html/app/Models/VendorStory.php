<?php

namespace App\Models;

use Carbon\Carbon;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Modules\Core\Entities\Item\Product;
use Modules\Core\Entities\Vendor\Vendor;

class VendorStory extends Model
{
    use HasFactory;

    protected $table = 'psx_vendor_stories';

    protected $fillable = [
        'user_id',
        'vendor_id',
        'media_type',
        'media_path',
        'thumbnail_path',
        'caption',
        'item_id',
        'filter_preset',
        'views_count',
        'duration',
        'expires_at',
        'added_date',
        'added_user_id',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
        'added_date' => 'datetime',
        'views_count' => 'integer',
        'duration' => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function vendor()
    {
        return $this->belongsTo(Vendor::class, 'vendor_id');
    }

    public function item()
    {
        return $this->belongsTo(Product::class, 'item_id');
    }

    public function views()
    {
        return $this->hasMany(VendorStoryView::class, 'story_id');
    }

    public function scopeActive($query)
    {
        return $query->where('expires_at', '>', Carbon::now());
    }

    public function getRemainingHoursAttribute()
    {
        if (!$this->expires_at) {
            return 0;
        }
        $diff = Carbon::now()->diffInHours($this->expires_at, false);
        return max(0, (int)$diff);
    }
}
