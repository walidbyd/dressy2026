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
     * Returns all deliverable Algerian wilayas as { code, name_fr, name_ar, name }.
     * Dynamically fetched from Yalidine API v1 without capping at 58.
     */
    public function wilayas(): JsonResponse
    {
        $wilayas = $this->shippingService->getWilayas();
        $formatted = [];

        foreach ($wilayas as $w) {
            $code = (int) ($w['id'] ?? $w['code'] ?? 0);
            $rawName = (string) ($w['name'] ?? $w['clean_name'] ?? '');
            $formatted[] = [
                'code' => $code,
                'name_fr' => $rawName ?: $this->shippingService->getWilayaNameFr($code),
                'name_ar' => $this->shippingService->getWilayaNameAr($code),
                'name' => $rawName ?: $this->shippingService->getWilayaNameFr($code),
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
     * Returns communes/regions and stop-desk centers for the requested wilaya.
     * Supports ?refresh=1 to bypass cache and query live Yalidine API.
     */
    public function communes(Request $request): JsonResponse
    {
        $wilayaRaw = $request->query('wilaya', $request->query('wilaya_code', $request->query('wilaya_id')));
        $wilayaCode = $this->shippingService->tryParseWilayaCode($wilayaRaw);

        if ($wilayaCode === null || $wilayaCode < 1) {
            return response()->json([
                'status' => 'error',
                'message' => 'A valid wilaya code is required.',
            ], 422);
        }

        $refresh = $request->boolean('refresh') || $request->query('refresh') === '1' || $request->query('refresh') === 'true';
        $communes = $this->shippingService->getCommunes($wilayaCode, $refresh);
        $centers = $this->shippingService->getCenters($wilayaCode, $refresh);
        $formatted = [];

        foreach ($communes as $c) {
            $formatted[] = [
                'id' => (int) ($c['id'] ?? 0),
                'name_fr' => (string) ($c['name'] ?? ''),
                'name_ar' => '',
                'name' => (string) ($c['name'] ?? ''),
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
            'centers' => $centers,
        ]);
    }

    /**
     * GET /api/v1.0/shipping/centers/{wilayaId?}
     * Returns all Yalidine Stop-Desk centers for the requested wilaya and optional commune.
     * Supports ?commune_id={id}&commune_name={name}&refresh=1
     */
    public function centers(Request $request, $wilayaId = null): JsonResponse
    {
        $wilayaRaw = $wilayaId
            ?? $request->query('wilaya', $request->query('wilaya_code', $request->query('wilaya_id')));
        $wilayaCode = $this->shippingService->tryParseWilayaCode($wilayaRaw) ?? 16;
        $communeId = $request->query('commune_id');
        if ($communeId !== null && is_numeric($communeId)) {
            $communeId = (int) $communeId;
        } else {
            $communeId = null;
        }
        $communeName = $request->query('commune_name') ?? $request->query('commune');
        $refresh = $request->boolean('refresh') || $request->query('refresh') === '1' || $request->query('refresh') === 'true';

        $result = $this->shippingService->getCentersDetailed($wilayaCode, $communeId, $communeName, $refresh);

        $httpStatus = ($result['success'] ?? false) ? 200 : 400;

        return response()->json(array_merge([
            'status' => ($result['success'] ?? false) ? 'success' : 'error',
            'courier' => 'yalidine',
            'wilaya_code' => $wilayaCode,
            'wilaya_id' => $wilayaCode,
            'wilaya_name_fr' => $this->shippingService->getWilayaNameFr($wilayaCode),
        ], $result), $httpStatus);
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
        if ($toWilayaCode === null || $toWilayaCode < 1) {
            return response()->json([
                'status' => 'error',
                'message' => 'A valid to_wilaya_code is required.',
            ], 422);
        }

        $itemId = $request->filled('item_id') ? (int) $request->input('item_id') : null;
        $vendorId = $request->filled('vendor_id') ? (int) $request->input('vendor_id') : null;
        $fromWilaya = $request->input('from_wilaya_code') ?? $request->input('from_wilaya_id') ?? $request->input('from_wilaya');
        $toCommuneName = $request->input('to_commune_name') ?? $request->input('commune_name') ?? $request->input('to_commune');
        $refresh = $request->boolean('refresh') || $request->query('refresh') === '1' || $request->query('refresh') === 'true';

        $quote = $this->shippingService->getYalidineQuote(
            $itemId,
            $toWilayaCode,
            is_string($toCommuneName) ? $toCommuneName : null,
            $fromWilaya,
            $vendorId,
            $refresh
        );

        return response()->json($quote);
    }
}
