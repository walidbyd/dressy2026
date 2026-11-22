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
            $imgPath = $vendor->logo->img_path;
            if (str_starts_with($imgPath, 'http://') || str_starts_with($imgPath, 'https://')) {
                $vendorLogo = $imgPath;
            } else {
                $clean = ltrim($imgPath, '/');
                $vendorLogo = (str_starts_with($clean, 'storage/') || str_starts_with($clean, 'uploads/'))
                    ? asset($clean)
                    : asset('storage/PSX_MPC/uploads/' . $clean);
            }
        } elseif ($user?->user_cover_photo) {
            $imgPath = $user->user_cover_photo;
            if (str_starts_with($imgPath, 'http://') || str_starts_with($imgPath, 'https://')) {
                $vendorLogo = $imgPath;
            } else {
                $clean = ltrim($imgPath, '/');
                $vendorLogo = (str_starts_with($clean, 'storage/') || str_starts_with($clean, 'uploads/'))
                    ? asset($clean)
                    : asset('storage/PSX_MPC/uploads/' . $clean);
            }
        }

        $userPhoto = '';
        if ($user?->user_cover_photo) {
            $imgPath = $user->user_cover_photo;
            if (str_starts_with($imgPath, 'http://') || str_starts_with($imgPath, 'https://')) {
                $userPhoto = $imgPath;
            } else {
                $clean = ltrim($imgPath, '/');
                $userPhoto = (str_starts_with($clean, 'storage/') || str_starts_with($clean, 'uploads/'))
                    ? asset($clean)
                    : asset('storage/PSX_MPC/uploads/' . $clean);
            }
        }

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
                $imgPath = $coverImg->img_path;
                if (str_starts_with($imgPath, 'http://') || str_starts_with($imgPath, 'https://')) {
                    $itemPhoto = $imgPath;
                } else {
                    $clean = ltrim($imgPath, '/');
                    $itemPhoto = (str_starts_with($clean, 'storage/') || str_starts_with($clean, 'uploads/'))
                        ? asset($clean)
                        : asset('storage/PSX_MPC/uploads/' . $clean);
                }
            }

            $currencySymbol = 'DZD';
            if ($item->currency && !empty($item->currency->currency_symbol)) {
                $currencySymbol = $item->currency->currency_symbol;
            } elseif ($item->itemCurrency && !empty($item->itemCurrency->currency_symbol)) {
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
