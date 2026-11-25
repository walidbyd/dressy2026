<?php

namespace App\Http\Controllers\Api\V1_0;

use App\Http\Controllers\Controller;
use App\Services\AffiliationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AffiliationApiController extends Controller
{
    public function __construct(protected AffiliationService $affiliationService)
    {
    }

    public function myDashboard(Request $request): JsonResponse
    {
        $userId = $request->query('login_user_id') ?? $request->input('login_user_id');
        if (!is_numeric($userId) || (int) $userId <= 0) {
            return response()->json([
                'status' => 'error',
                'message' => 'Authentification requise.',
            ], 401);
        }

        $data = $this->affiliationService->getUserDashboard((int) $userId);

        return response()->json([
            'status' => 'success',
            'data' => $data,
        ]);
    }

    public function validateCode(Request $request): JsonResponse
    {
        $code = (string) ($request->input('code') ?? '');
        $subtotal = (float) ($request->input('subtotal') ?? 0);
        $userId = $request->input('login_user_id') ?? $request->query('login_user_id');
        $uid = is_numeric($userId) ? (int) $userId : null;

        $result = $this->affiliationService->validateCode($code, $uid, $subtotal);
        $statusCode = !empty($result['valid']) ? 200 : 422;

        return response()->json($result, $statusCode);
    }
}
