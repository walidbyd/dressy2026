<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\File;
use Modules\Core\Entities\CoreImage;
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

        // Resolve vendor / seller name & avatar
        $vendorName = $vendor?->name ?? $user?->name ?? 'Dressy Vendeur';
        $vendorLogoPath = '';
        $vendorLogoUrl = '';

        if (!empty($this->vendor_id) && (int)$this->vendor_id > 0) {
            $vLogo = $vendor?->logo?->img_path ?? CoreImage::where('img_parent_id', $this->vendor_id)
                ->where('img_type', 'vendor-logo')
                ->value('img_path');
            if (!empty($vLogo)) {
                $vendorLogoPath = $vLogo;
            }
        }

        if (empty($vendorLogoPath) && $user) {
            if (!empty($user->user_cover_photo)) {
                $vendorLogoPath = $user->user_cover_photo;
            } elseif (!empty($user->user_profile_photo)) {
                $vendorLogoPath = $user->user_profile_photo;
            }
        }

        if (!empty($vendorLogoPath)) {
            if (str_starts_with($vendorLogoPath, 'http://') || str_starts_with($vendorLogoPath, 'https://')) {
                $vendorLogoUrl = $vendorLogoPath;
            } else {
                $clean = ltrim($vendorLogoPath, '/');
                if (File::exists(public_path('storage/PSX_MPC/uploads/' . $clean))) {
                    $vendorLogoUrl = asset('storage/PSX_MPC/uploads/' . $clean);
                } elseif (File::exists(public_path('uploads/' . $clean))) {
                    $vendorLogoUrl = asset('uploads/' . $clean);
                } else {
                    $vendorLogoUrl = asset('storage/PSX_MPC/uploads/' . $clean);
                }
            }
        }

        // Story Media: relative path and full URL served reliably from public/uploads/
        $rawMediaPath = $this->media_path ?? '';
        $cleanMediaPath = ltrim(preg_replace('#^/?uploads/#', '', $rawMediaPath), '/');
        $mediaUrl = '';
        if (!empty($rawMediaPath)) {
            if (str_starts_with($rawMediaPath, 'http://') || str_starts_with($rawMediaPath, 'https://')) {
                $mediaUrl = $rawMediaPath;
            } else {
                $mediaUrl = url('uploads/' . $cleanMediaPath);
            }
        }

        $rawThumbPath = $this->thumbnail_path ?? '';
        $cleanThumbPath = ltrim(preg_replace('#^/?uploads/#', '', $rawThumbPath), '/');
        $thumbnailUrl = '';
        if (!empty($rawThumbPath)) {
            if (str_starts_with($rawThumbPath, 'http://') || str_starts_with($rawThumbPath, 'https://')) {
                $thumbnailUrl = $rawThumbPath;
            } else {
                $thumbnailUrl = url('uploads/' . $cleanThumbPath);
            }
        } elseif ($this->media_type === 'image') {
            $thumbnailUrl = $mediaUrl;
        }

        // Tagged item detail with defaultPhoto eager loading
        $itemTitle = '';
        $itemPrice = '';
        $currencySymbol = 'DZD';
        $itemImagePath = '';
        $itemImageUrl = '';
        $taggedItem = null;

        if ($item) {
            $itemTitle = (string) ($item->title ?? '');
            $itemPrice = (string) ($item->price ?? '0');
            if ($item->currency && !empty($item->currency->currency_symbol)) {
                $currencySymbol = (string) $item->currency->currency_symbol;
            } elseif ($item->itemCurrency && !empty($item->itemCurrency->currency_symbol)) {
                $currencySymbol = (string) $item->itemCurrency->currency_symbol;
            }

            $coverImg = $item->cover?->first() ?? $item->defaultPhoto;
            if (!$coverImg && isset($item->id)) {
                $coverImg = CoreImage::where('img_parent_id', $item->id)
                    ->where('img_type', 'item')
                    ->orderBy('ordering', 'asc')
                    ->first();
            }

            if ($coverImg && !empty($coverImg->img_path)) {
                $itemImagePath = $coverImg->img_path;
                if (str_starts_with($itemImagePath, 'http://') || str_starts_with($itemImagePath, 'https://')) {
                    $itemImageUrl = $itemImagePath;
                } else {
                    $cleanImg = ltrim($itemImagePath, '/');
                    if (File::exists(public_path('storage/PSX_MPC/uploads/' . $cleanImg))) {
                        $itemImageUrl = asset('storage/PSX_MPC/uploads/' . $cleanImg);
                    } elseif (File::exists(public_path('uploads/' . $cleanImg))) {
                        $itemImageUrl = asset('uploads/' . $cleanImg);
                    } else {
                        $itemImageUrl = asset('storage/PSX_MPC/uploads/' . $cleanImg);
                    }
                }
            }

            $taggedItem = [
                'id' => (string) $item->id,
                'title' => $itemTitle,
                'price' => $itemPrice,
                'original_price' => (string) ($item->original_price ?? '0'),
                'currency_symbol' => $currencySymbol,
                'image_path' => $itemImagePath,
                'image_url' => $itemImageUrl,
                'photo' => $itemImageUrl,
            ];
        }

        $isOwner = (!empty($loginUserId) && (string)$loginUserId !== 'nologinuser' && (string)$loginUserId === (string)$this->user_id);
        $isBoosted = (bool) ($this->is_boosted ?? false)
            && !empty($this->boost_expires_at)
            && Carbon::parse($this->boost_expires_at)->gt(Carbon::now());

        return [
            'id' => (string) $this->id,
            'is_boosted' => $isBoosted,
            'boost_expires_at' => $isBoosted ? Carbon::parse($this->boost_expires_at)->toIso8601String() : '',
            'user_id' => (string) $this->user_id,
            'vendor_id' => $this->vendor_id ? (string) $this->vendor_id : '',
            'vendor_name' => $vendorName,
            'vendor_logo' => $vendorLogoUrl,
            'vendor_logo_path' => $vendorLogoPath,
            'avatar_path' => $vendorLogoPath,
            'avatar_url' => $vendorLogoUrl,
            'user_name' => (string) ($user?->name ?? $vendorName),
            'user_photo' => $vendorLogoUrl,
            'media_type' => (string) ($this->media_type ?? 'image'),
            'media_path' => (string) $cleanMediaPath,
            'media_url' => (string) $mediaUrl,
            'thumbnail_path' => (string) $cleanThumbPath,
            'thumbnail_url' => (string) $thumbnailUrl,
            'caption' => (string) ($this->caption ?? ''),
            'item_id' => $this->item_id ? (string) $this->item_id : '',
            'item_title' => $itemTitle,
            'item_price' => $itemPrice,
            'currency_symbol' => $currencySymbol,
            'item_image_path' => $itemImagePath,
            'item_image_url' => $itemImageUrl,
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
