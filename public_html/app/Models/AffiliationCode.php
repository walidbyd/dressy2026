<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AffiliationCode extends Model
{
    protected $table = 'psx_affiliation_codes';

    protected $fillable = [
        'user_id',
        'code',
        'is_active',
    ];

    protected $casts = [
        'user_id' => 'integer',
        'is_active' => 'boolean',
    ];

    public function issuer()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function referrals()
    {
        return $this->hasMany(AffiliationReferral::class, 'affiliation_code_id');
    }
}
