<?php

namespace App\Http\Controllers\Api\V1_0;

use App\Http\Controllers\Controller;
use App\Services\DisputeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Modules\StoreFront\VendorPanel\Entities\Order;

class DisputeApiController extends Controller
{
    public function __construct(protected DisputeService $disputeService)
    {
    }

    public function store(Request $request, int $orderId): JsonResponse
    {
        $validated = $request->validate([
            'dispute_type' => ['required', 'string', Rule::in(DisputeService::DISPUTE_TYPES)],
            'description' => 'required|string|min:5|max:2000',
        ]);

        $userId = $request->input('login_user_id') ?? $request->query('login_user_id') ?? ($request->user()?->id);
        if (!is_numeric($userId) || (int) $userId <= 0) {
            return response()->json(['status' => 'error', 'message' => 'Authentification requise.'], 401);
        }

        $order = Order::with(['vendor', 'orderItems'])->find($orderId);
        if (!$order) {
            return response()->json(['status' => 'error', 'message' => 'Commande introuvable.'], 404);
        }

        $result = $this->disputeService->createDispute(
            $order,
            (int) $userId,
            $validated['dispute_type'],
            $validated['description']
        );

        return response()->json([
            'status' => !empty($result['success']) ? 'success' : 'error',
            'message' => $result['message'],
            'dispute' => $result['dispute'] ?? null,
        ], $result['status_code']);
    }
}
