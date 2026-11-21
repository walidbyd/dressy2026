<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Crypt;

class DeliverySetting extends Model
{
    use HasFactory;

    protected $table = 'psx_delivery_settings';

    protected $fillable = [
        'is_enabled',
        'environment',
        'api_base_url',
        'api_id',
        'api_token',
        'auto_create_parcel',
        'auto_sync_trigger',
        'auto_sync_status',
        'webhook_secret',
        'sender_name',
        'sender_phone',
        'from_wilaya_id',
        'from_commune_name',
        'from_stop_desk_id',
        'default_delivery_type',
        'is_free_shipping',
        'free_shipping_min_amount',
        'has_insurance',
        'open_parcel',
        'description_prefix',
    ];

    protected $casts = [
        'is_enabled' => 'boolean',
        'auto_create_parcel' => 'boolean',
        'auto_sync_status' => 'boolean',
        'is_free_shipping' => 'boolean',
        'has_insurance' => 'boolean',
        'open_parcel' => 'boolean',
        'free_shipping_min_amount' => 'decimal:2',
        'from_wilaya_id' => 'integer',
    ];

    /**
     * Mutator to encrypt api_token before storing.
     */
    public function setApiTokenAttribute($value): void
    {
        if (!empty($value)) {
            $this->attributes['api_token'] = Crypt::encryptString(trim((string) $value));
        } else {
            $this->attributes['api_token'] = null;
        }
    }

    /**
     * Accessor to decrypt api_token when reading.
     */
    public function getApiTokenAttribute($value): ?string
    {
        if (empty($value)) {
            return null;
        }
        try {
            return Crypt::decryptString($value);
        } catch (\Throwable $e) {
            return $value; // Fallback in case raw token was stored
        }
    }

    /**
     * Retrieve the singleton settings record, creating default if not exists.
     */
    public static function getSettings(): self
    {
        $setting = self::first();
        if (!$setting) {
            $setting = self::create([
                'is_enabled' => true,
                'environment' => env('YALIDINE_STUB_MODE', true) ? 'sandbox' : 'production',
                'api_base_url' => env('YALIDINE_API_URL', 'https://api.yalidine.app/v1'),
                'api_id' => env('YALIDINE_API_ID', ''),
                'api_token' => env('YALIDINE_API_TOKEN', ''),
                'auto_create_parcel' => true,
                'auto_sync_trigger' => 'on_seller_confirmed',
                'auto_sync_status' => true,
                'webhook_secret' => bin2hex(random_bytes(16)),
                'sender_name' => 'Dressy DZ',
                'sender_phone' => '0550000000',
                'from_wilaya_id' => 16,
                'from_commune_name' => 'Alger',
                'from_stop_desk_id' => null,
                'default_delivery_type' => 'home',
                'is_free_shipping' => false,
                'free_shipping_min_amount' => 0.00,
                'has_insurance' => false,
                'open_parcel' => true,
                'description_prefix' => 'Article Mode Dressy',
            ]);
        }
        return $setting;
    }
}
