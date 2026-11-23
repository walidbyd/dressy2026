<?php

namespace App\Http\Controllers\Api\V1_0;

use App\Http\Controllers\Controller;
use App\Services\YalidineService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ShippingApiController extends Controller
{
    protected YalidineService $shippingService;

    public function __construct(YalidineService $shippingService)
    {
        $this->shippingService = $shippingService;
    }

    /**
     * GET /api/v1.0/shipping/wilayas
     * Returns the 58 shippable Algerian wilayas as { code, name_fr, name_ar }.
     */
    public function wilayas(): JsonResponse
    {
        $wilayas = $this->shippingService->getWilayas();
        $formatted = [];

        foreach ($wilayas as $w) {
            $code = (int) ($w['id'] ?? $w['code'] ?? 0);
            $formatted[] = [
                'code' => $code,
                'name_fr' => $this->shippingService->getWilayaNameFr($code),
                'name_ar' => $this->shippingService->getWilayaNameAr($code),
                'name' => $w['name'] ?? $this->shippingService->getWilayaNameFr($code),
            ];
        }

        return response()->json([
            'status' => 'success',
            'courier' => 'yalidine',
            'count' => count($formatted),
            'wilayas' => $formatted,
        ]);
    }

    /**
     * GET /api/v1.0/shipping/communes?wilaya={code}
     * Returns communes/regions for the requested wilaya as { id, name_fr, name_ar, wilaya_code }.
     */
    public function communes(Request $request): JsonResponse
    {
        $wilayaRaw = $request->query('wilaya', $request->query('wilaya_code', $request->query('wilaya_id')));
        $wilayaCode = $this->shippingService->tryParseWilayaCode($wilayaRaw);

        if ($wilayaCode === null) {
            return response()->json([
                'status' => 'error',
                'message' => 'A valid wilaya code (1-58) is required.',
            ], 422);
        }

        $communes = $this->shippingService->getCommunes($wilayaCode);
        $formatted = [];

        foreach ($communes as $c) {
            $formatted[] = [
                'id' => (int) ($c['id'] ?? 0),
                'name_fr' => (string) ($c['name'] ?? ''),
                'name_ar' => '',
                'wilaya_code' => $wilayaCode,
                'has_stop_desk' => (bool) ($c['has_stop_desk'] ?? false),
            ];
        }

        return response()->json([
            'status' => 'success',
            'courier' => 'yalidine',
            'wilaya_code' => $wilayaCode,
            'wilaya_name_fr' => $this->shippingService->getWilayaNameFr($wilayaCode),
            'wilaya_name_ar' => $this->shippingService->getWilayaNameAr($wilayaCode),
            'count' => count($formatted),
            'communes' => $formatted,
        ]);
    }

    /**
     * POST /api/v1.0/shipping/yalidine-quote
     * Accepts item_id, to_wilaya_code, and optional to_commune_name.
     * Returns both Yalidine Stop-Desk (price_dzd + desks[]) and Yalidine Home Delivery (price_dzd).
     */
    public function yalidineQuote(Request $request): JsonResponse
    {
        $toWilayaRaw = $request->input('to_wilaya_code')
            ?? $request->input('to_wilaya_id')
            ?? $request->input('wilaya_code')
            ?? $request->input('wilaya');

        $toWilayaCode = $this->shippingService->tryParseWilayaCode($toWilayaRaw);
        if ($toWilayaCode === null) {
            return response()->json([
                'status' => 'error',
                'message' => 'A valid to_wilaya_code (1-58) is required.',
            ], 422);
        }

        $itemId = $request->filled('item_id') ? (int) $request->input('item_id') : null;
        $vendorId = $request->filled('vendor_id') ? (int) $request->input('vendor_id') : null;
        $fromWilaya = $request->input('from_wilaya_code') ?? $request->input('from_wilaya_id') ?? $request->input('from_wilaya');
        $toCommuneName = $request->input('to_commune_name') ?? $request->input('commune_name') ?? $request->input('to_commune');

        $quote = $this->shippingService->getYalidineQuote(
            $itemId,
            $toWilayaCode,
            is_string($toCommuneName) ? $toCommuneName : null,
            $fromWilaya,
            $vendorId
        );

        return response()->json($quote);
    }
}
