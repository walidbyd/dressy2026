<?php

namespace App\Http\Controllers\Api\V1_0;

use App\Http\Controllers\Controller;
use App\Services\SilkpayService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SilkpayApiController extends Controller
{
    public function __construct(protected SilkpayService $silkpayService)
    {
    }

    public function topupPacks(): JsonResponse
    {
        $settings = $this->silkpayService->getSettings();
        $packs = $this->silkpayService->getActivePacks()->map(fn ($p) => [
            'id' => $p->id,
            'amount_dzd' => (float) $p->amount_dzd,
            'title' => $p->title,
            'payment_url' => $p->payment_url ?? '',
            'is_active' => (bool) $p->is_active,
        ])->values()->all();

        return response()->json([
            'status' => 'success',
            'is_active' => (bool) $settings->is_active,
            'packs' => $packs,
        ]);
    }

    public function initiate(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'pack_id' => 'required|integer|exists:psx_silkpay_packs,id',
        ]);

        $userId = $request->input('login_user_id') ?? $request->query('login_user_id') ?? $request->user()?->id;
        if (!is_numeric($userId) || (int) $userId <= 0) {
            return response()->json(['status' => 'error', 'message' => 'Authentification requise.'], 401);
        }

        $res = $this->silkpayService->initiateTopup((int) $userId, (int) $validated['pack_id']);
        return response()->json($res, $res['status_code']);
    }

    public function webhook(Request $request): JsonResponse
    {
        $rawBody = $request->getContent();
        $payload = $request->all();
        if (empty($payload) && $rawBody !== '') {
            $decoded = json_decode($rawBody, true);
            if (is_array($decoded)) {
                $payload = $decoded;
            }
        }

        $sig = $request->header('X-Silkpay-Signature')
            ?? $request->header('X-Webhook-Signature')
            ?? $request->header('X-Signature')
            ?? $request->input('signature');

        $res = $this->silkpayService->handleWebhook($payload, is_string($sig) ? $sig : null, $rawBody);
        return response()->json($res, $res['status_code']);
    }
}
