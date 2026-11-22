<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;
use Carbon\Carbon;

class StoryApiResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return array
     */
    public function toArray($request)
    {
        $loginUserId = $request->header('login_user_id') 
            ?? $request->query('login_user_id') 
            ?? $request->input('login_user_id') 
            ?? $request->user()?->id;

        $user = $this->user;
        $vendor = $this->vendor;
        $item = $this->item;

        // Resolve vendor name & logo
        $vendorName = $vendor?->name ?? $user?->name ?? 'Dressy Vendeur';
        $vendorLogo = '';
        if ($vendor?->logo?->img_path) {
            $vendorLogo = asset('storage/uploads/' . $vendor->logo->img_path);
        } elseif ($user?->user_cover_photo) {
            $vendorLogo = asset('storage/uploads/' . $user->user_cover_photo);
        }

        $userPhoto = $user?->user_cover_photo ? asset('storage/uploads/' . $user->user_cover_photo) : '';

        // Media full URLs
        $mediaUrl = $this->media_path;
        if (!empty($mediaUrl) && !str_starts_with($mediaUrl, 'http://') && !str_starts_with($mediaUrl, 'https://')) {
            $mediaUrl = asset($mediaUrl);
        }

        $thumbnailUrl = $this->thumbnail_path;
        if (!empty($thumbnailUrl) && !str_starts_with($thumbnailUrl, 'http://') && !str_starts_with($thumbnailUrl, 'https://')) {
            $thumbnailUrl = asset($thumbnailUrl);
        } elseif (empty($thumbnailUrl) && $this->media_type === 'image') {
            $thumbnailUrl = $mediaUrl;
        }

        // Tagged item detail
        $taggedItem = null;
        if ($item) {
            $itemPhoto = '';
            $coverImg = $item->defaultPhoto ?? $item->cover?->first();
            if ($coverImg && !empty($coverImg->img_path)) {
                $itemPhoto = asset('storage/uploads/' . $coverImg->img_path);
            }

            $currencySymbol = 'DZD';
            if ($item->itemCurrency && !empty($item->itemCurrency->currency_symbol)) {
                $currencySymbol = $item->itemCurrency->currency_symbol;
            }

            $taggedItem = [
                'id' => (string) $item->id,
                'title' => (string) ($item->title ?? ''),
                'price' => (string) ($item->price ?? '0'),
                'original_price' => (string) ($item->original_price ?? '0'),
                'currency_symbol' => $currencySymbol,
                'photo' => $itemPhoto,
            ];
        }

        $isOwner = (!empty($loginUserId) && (string)$loginUserId !== 'nologinuser' && (string)$loginUserId === (string)$this->user_id);

        return [
            'id' => (string) $this->id,
            'user_id' => (string) $this->user_id,
            'vendor_id' => $this->vendor_id ? (string) $this->vendor_id : '',
            'vendor_name' => $vendorName,
            'vendor_logo' => $vendorLogo,
            'user_name' => (string) ($user?->name ?? $vendorName),
            'user_photo' => $userPhoto,
            'media_type' => (string) ($this->media_type ?? 'image'),
            'media_url' => (string) $mediaUrl,
            'thumbnail_url' => (string) $thumbnailUrl,
            'caption' => (string) ($this->caption ?? ''),
            'item_id' => $this->item_id ? (string) $this->item_id : '',
            'item' => $taggedItem,
            'filter_preset' => (string) ($this->filter_preset ?? 'original'),
            'views_count' => (int) ($this->views_count ?? 0),
            'duration' => (int) ($this->duration ?? 5),
            'created_at' => $this->created_at ? $this->created_at->format('Y-m-d H:i:s') : (string) $this->added_date,
            'expires_at' => $this->expires_at ? $this->expires_at->format('Y-m-d H:i:s') : '',
            'remaining_hours' => $this->remaining_hours,
            'time_ago' => $this->created_at ? $this->created_at->diffForHumans() : '',
            'is_owner' => $isOwner,
        ];
    }
}
