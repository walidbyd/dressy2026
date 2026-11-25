<?php

namespace App\Http\Controllers\Api\V1_0;

use App\Http\Controllers\Controller;
use App\Services\AdBoostService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Modules\Core\Entities\Item\Item;
use Modules\Core\Entities\Vendor\Vendor;

class AdBoostApiController extends Controller
{
    public function __construct(protected AdBoostService $adBoostService)
    {
    }

    public function config(): JsonResponse
    {
        return response()->json([
            'status' => 'success',
            'data' => $this->adBoostService->getPublicConfig(),
        ]);
    }

    public function myItems(Request $request): JsonResponse
    {
        $userId = $request->query('login_user_id') ?? $request->input('login_user_id') ?? $request->user()?->id;
        if (!is_numeric($userId) || (int) $userId <= 0) {
            return response()->json(['status' => 'error', 'message' => 'Authentification requise.'], 401);
        }
        $uid = (int) $userId;
        $vendorIds = Vendor::where('owner_user_id', $uid)->pluck('id')->all();

        $items = Item::with(['cover', 'currency'])
            ->where(function ($q) use ($uid, $vendorIds) {
                $q->where('added_user_id', $uid);
                if (!empty($vendorIds)) {
                    $q->orWhereIn('vendor_id', $vendorIds);
                }
            })
            ->where('status', 1)
            ->orderByDesc('id')
            ->limit(100)
            ->get()
            ->map(function (Item $item) {
                $now = Carbon::now();
                $isBoosted = (bool) ($item->is_boosted ?? false)
                    && !empty($item->boost_expires_at)
                    && Carbon::parse($item->boost_expires_at)->gt($now);

                $imgPath = $item->cover?->first()?->img_path ?? '';
                $imgUrl = $imgPath !== '' ? asset('storage/PSX_MPC/uploads/' . ltrim($imgPath, '/')) : '';

                return [
                    'id' => (string) $item->id,
                    'title' => (string) $item->title,
                    'price' => (float) $item->price,
                    'currency' => (string) ($item->currency?->currency_symbol ?? 'DA'),
                    'image_url' => $imgUrl,
                    'is_boosted' => $isBoosted,
                    'boost_expires_at' => $isBoosted ? Carbon::parse($item->boost_expires_at)->toIso8601String() : null,
                ];
            })
            ->values()
            ->all();

        return response()->json([
            'status' => 'success',
            'items' => $items,
        ]);
    }

    public function boostStory(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'story_id' => 'required|integer|exists:psx_vendor_stories,id',
        ]);

        $userId = $request->input('login_user_id') ?? $request->query('login_user_id') ?? $request->user()?->id;
        if (!is_numeric($userId) || (int) $userId <= 0) {
            return response()->json(['status' => 'error', 'message' => 'Authentification requise.'], 401);
        }

        $res = $this->adBoostService->boostStory((int) $userId, (int) $validated['story_id']);
        return response()->json($res, $res['status_code']);
    }

    public function boostItem(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'item_id' => 'required|integer|exists:psx_items,id',
            'tier' => ['required', 'string', Rule::in(['daily', 'weekly', 'monthly'])],
        ]);

        $userId = $request->input('login_user_id') ?? $request->query('login_user_id') ?? $request->user()?->id;
        if (!is_numeric($userId) || (int) $userId <= 0) {
            return response()->json(['status' => 'error', 'message' => 'Authentification requise.'], 401);
        }

        $res = $this->adBoostService->boostItem((int) $userId, (int) $validated['item_id'], $validated['tier']);
        return response()->json($res, $res['status_code']);
    }
}
