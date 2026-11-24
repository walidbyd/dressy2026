<?php

namespace App\Http\Controllers\Api\V1_0;

use App\Http\Controllers\Controller;
use App\Services\CouponService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CouponApiController extends Controller
{
    public function __construct(protected CouponService $couponService)
    {
    }

    public function myCoupons(Request $request): JsonResponse
    {
        $userId = $request->query('login_user_id') ?? $request->input('login_user_id');
        $uid = is_numeric($userId) ? (int) $userId : null;

        $coupons = $this->couponService->getUserAvailableCoupons($uid);

        return response()->json([
            'status' => 'success',
            'coupons' => $coupons,
        ]);
    }

    public function validateCode(Request $request): JsonResponse
    {
        $code = (string) ($request->input('code') ?? '');
        $subtotal = (float) ($request->input('subtotal') ?? 0);
        $userId = $request->input('login_user_id') ?? $request->query('login_user_id');
        $uid = is_numeric($userId) ? (int) $userId : null;

        $result = $this->couponService->validateCoupon($code, $uid, $subtotal);
        $statusCode = !empty($result['valid']) ? 200 : 422;

        return response()->json($result, $statusCode);
    }

    public function rouletteStatus(Request $request): JsonResponse
    {
        $userId = $request->query('login_user_id') ?? $request->input('login_user_id');
        $uid = is_numeric($userId) ? (int) $userId : null;

        return response()->json($this->couponService->checkRouletteEligibility($uid));
    }

    public function rouletteSpin(Request $request): JsonResponse
    {
        $userId = $request->input('login_user_id') ?? $request->query('login_user_id');
        if (!is_numeric($userId) || (int) $userId <= 0) {
            return response()->json([
                'success' => false,
                'message' => 'Authentification requise.',
            ], 401);
        }

        $result = $this->couponService->spinRoulette((int) $userId);
        return response()->json($result, !empty($result['success']) ? 200 : 429);
    }
}
