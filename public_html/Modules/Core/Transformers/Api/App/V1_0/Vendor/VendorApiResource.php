<?php

namespace Modules\Core\Transformers\Api\App\V1_0\Vendor;

use Carbon\Carbon;
use Illuminate\Http\Resources\Json\JsonResource;
use Modules\Core\Constants\Constants;
use Modules\Core\Entities\Configuration\Setting;
use Modules\Core\Transformers\Api\App\V1_0\CoreImage\CoreImageApiResource;

class VendorApiResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @param  \Illuminate\Http\Request
     * @return array
     */
    public function toArray($request)
    {
        if (empty(checkAndGetValue($this, 'id'))) {
            return [
                'id' => '',
                'owner_user_id' => '',
                'status' => '',
                'name' => '',
                'phone' => '',
                'email' => '',
                'address' => '',
                'description' => '',
                'website' => '',
                'facebook' => '',
                'instagram' => '',
                'product_count' => '0',
                'currency_id' => '',
                'added_date' => '',
                'expired_date' => '',
                'expire_status' => 0,
                'follower_count' => '0',
                'following_count' => '0',
                'is_followed' => '0',
                'overall_rating' => '0',
                'rating_count' => '0',
                'logo' => new CoreImageApiResource([]),
                'banner_1' => new CoreImageApiResource([]),
                'banner_2' => new CoreImageApiResource([]),
                'vendor_application' => new VendorApplicationApiResource([]),
                'added_date_str' => '',
                'is_empty_object' => '1',
                'updated_flag' => '',
                'vendorRelation' => [],
            ];
        }

        $product_count = productCountByVendorId($this->id);

        $vendor_subcription_setting = Setting::select('setting')->where('setting_env', Constants::VENDOR_SUBSCRIPTION_CONFIG)->first();
        $jsonSetting = json_decode($vendor_subcription_setting->setting, true);
        $idValue = $jsonSetting['subscription_plan'][0]['id'];
        $noticDays = $jsonSetting['notic_days'];

        // for vendor expery status
        $expireStatus = 0;
        if ($idValue != 'FREE') {
            if (isset($this->expired_date)) {
                $currentDate = Carbon::now();
                $notiDate = Carbon::parse($this->expired_date)->subDays((int) $noticDays - 1);
                $expiredDate = Carbon::parse($this->expired_date);

                if ($currentDate->lt($notiDate)) {
                    $expireStatus = 0; // not show noti
                }
                if (($currentDate->gt($notiDate) || $currentDate->eq($notiDate)) && $currentDate->lt($expiredDate)) {
                    $expireStatus = 1; // show warning noti
                }
                if ($currentDate->gt(Carbon::parse($this->expired_date)->subDays(1))) {
                    $expireStatus = 2; // show expired noti
                }
                if ($this->is_unlimited) {
                    $expireStatus = 0;
                }
            }
        }

        $ownerId = checkAndGetValue($this, 'owner_user_id');
        $vendorId = checkAndGetValue($this, 'id');
        $owner = $ownerId ? \App\Models\User::find($ownerId) : null;
        $loginUserId = $request->query('login_user_id') ?? $request->login_user_id ?? $request->user_id ?? $request->user()?->id;

        $followerCount = 0;
        $followingCount = 0;
        $isFollowed = '0';
        $overallRating = '0.0';
        $ratingCount = '0';

        if ($ownerId) {
            $followerCount = \Modules\Core\Entities\User\FollowUser::where('followed_user_id', $ownerId)->count();
            $followingCount = \Modules\Core\Entities\User\FollowUser::where('user_id', $ownerId)->count();
            if ($loginUserId) {
                $isFollowed = \Modules\Core\Entities\User\FollowUser::where(['user_id' => $loginUserId, 'followed_user_id' => $ownerId])->exists() ? '1' : '0';
            }
        }

        $ratingsQuery = \Modules\Core\Entities\User\Rating::query()->where(function ($q) use ($ownerId, $vendorId) {
            if ($ownerId) {
                $q->where('to_user_id', $ownerId);
            }
            if ($vendorId) {
                $q->orWhere('to_user_id', $vendorId)
                  ->orWhere('shop_id', $vendorId);
            }
        });

        $ratingCountInt = $ratingsQuery->count();
        $ratingCount = (string) $ratingCountInt;
        if ($ratingCountInt > 0) {
            $avg = $ratingsQuery->avg('rating');
            $overallRating = number_format((float) $avg, 1, '.', '');
        } elseif ($owner && ! empty($owner->overall_rating) && (float) $owner->overall_rating > 0) {
            $overallRating = number_format((float) $owner->overall_rating, 1, '.', '');
        } elseif (! empty($this->overall_rating) && (float) $this->overall_rating > 0) {
            $overallRating = number_format((float) $this->overall_rating, 1, '.', '');
        }

        $logoImage = $this->logo;
        if (! $logoImage && $owner && ! empty($owner->user_cover_photo)) {
            $logoImage = new \Modules\Core\Entities\CoreImage([
                'img_parent_id' => $this->id,
                'img_type' => Constants::vendorLogoImgType,
                'img_path' => $owner->user_cover_photo,
            ]);
        }

        $isOwner = !empty($loginUserId) && $loginUserId != 'nologinuser' && (string)$loginUserId === (string)$ownerId;

        return [
            'id' => checkAndGetValue($this, 'id'),
            'owner_user_id' => checkAndGetValue($this, 'owner_user_id'),
            'status' => checkAndGetValue($this, 'status'),
            'name' => checkAndGetValue($this, 'name'),
            'phone' => $isOwner ? checkAndGetValue($this, 'phone') : '',
            'email' => $isOwner ? checkAndGetValue($this, 'email') : '',
            'address' => checkAndGetValue($this, 'address'),
            'description' => checkAndGetValue($this, 'description'),
            'website' => $isOwner ? checkAndGetValue($this, 'website') : '',
            'facebook' => $isOwner ? checkAndGetValue($this, 'facebook') : '',
            'instagram' => $isOwner ? checkAndGetValue($this, 'instagram') : '',
            'product_count' => (string) $product_count,
            'currency_id' => checkAndGetValue($this, 'currency_id'),
            'added_date' => checkAndGetValue($this, 'added_date'),
            'expired_date' => checkAndGetValue($this, 'expired_date'),
            'expire_status' => $expireStatus,
            'follower_count' => (string) $followerCount,
            'following_count' => (string) $followingCount,
            'is_followed' => (string) $isFollowed,
            'overall_rating' => (string) $overallRating,
            'rating_count' => (string) $ratingCount,
            'logo' => new CoreImageApiResource($logoImage ?? []),
            'banner_1' => new CoreImageApiResource(checkAndGetValue($this, 'banner_1') && $this->banner_1 ? $this->whenLoaded('banner_1') : []),
            'banner_2' => new CoreImageApiResource(checkAndGetValue($this, 'banner_2') && $this->banner_2 ? $this->whenLoaded('banner_2') : []),
            'vendor_application' => new VendorApplicationApiResource(checkAndGetValue($this, 'owner_user_id') && checkAndGetValue($this, 'vendor_application') ? $this->whenLoaded('vendor_application') : []),
            'added_date_str' => checkAndGetValue($this, 'added_date') ? (string) $this->added_date->diffForHumans() : '',
            'is_empty_object' => checkAndGetValue($this, 'id', 1),
            'updated_flag' => checkAndGetValue($this, 'updated_flag'),
            'vendorRelation' => VendorInfoApiResource::collection($this->vendorInfo ?? []),
        ];
    }
}
