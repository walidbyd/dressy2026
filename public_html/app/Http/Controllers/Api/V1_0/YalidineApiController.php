<?php

namespace App\Http\Controllers\Api\V1_0;

use App\Http\Controllers\Controller;
use App\Services\YalidineService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Modules\Core\Constants\Constants;
use Modules\StoreFront\VendorPanel\Entities\Order;

class YalidineApiController extends Controller
{
    protected YalidineService $yalidineService;

    public function __construct(YalidineService $yalidineService)
    {
        $this->yalidineService = $yalidineService;
    }

    /**
     * Get Yalidine Stop-Desk centers for a wilaya and optional commune.
     *
     * GET /api/v1/yalidine/centers/{wilayaId?}
     * GET /api/v1.0/yalidine/centers/{wilayaId?}
     *
     * Supports ?commune_id={id}&commune_name={name}&refresh=1
     */
    public function centers(Request $request, $wilayaId = null): JsonResponse
    {
        $rawId = $wilayaId
            ?? $request->query('wilaya_id')
            ?? $request->query('wilaya')
            ?? $request->query('wilaya_code')
            ?? 16;

        $id = $this->yalidineService->normalizeWilayaId($rawId);
        $communeId = $request->query('commune_id');
        if ($communeId !== null && is_numeric($communeId)) {
            $communeId = (int) $communeId;
        } else {
            $communeId = null;
        }
        $communeName = $request->query('commune_name') ?? $request->query('commune');
        $refresh = $request->boolean('refresh') || $request->query('refresh') === '1' || $request->query('refresh') === 'true';

        $result = $this->yalidineService->getCentersDetailed($id, $communeId, $communeName, $refresh);

        $httpStatus = ($result['success'] ?? false) ? 200 : 400;

        return response()->json(array_merge([
            'status' => ($result['success'] ?? false) ? 'success' : 'error',
            'courier' => 'yalidine',
            'wilaya_id' => $id,
            'wilaya_code' => $id,
            'wilaya_name' => $this->yalidineService->getWilayaNameFr($id),
            'wilaya_name_fr' => $this->yalidineService->getWilayaNameFr($id),
        ], $result), $httpStatus);
    }

    /**
     * Get Yalidine Wilayas, Communes, and Stop Desk centers.
     *
     * GET /api/v1.0/yalidine/locations?wilaya_id=16
     */
    public function locations(Request $request): JsonResponse
    {
        $wilayaId = $request->query('wilaya_id');
        $refresh = $request->boolean('refresh') || $request->query('refresh') === '1' || $request->query('refresh') === 'true';

        if (!empty($wilayaId)) {
            $id = $this->yalidineService->normalizeWilayaId($wilayaId);
            $communeId = $request->query('commune_id');
            $communeName = $request->query('commune_name') ?? $request->query('commune');
            $communes = $this->yalidineService->getCommunes($id, $refresh);
            $centers = $this->yalidineService->getCenters($id, $communeId, $communeName, $refresh);

            return response()->json([
                'status' => 'success',
                'wilaya_id' => $id,
                'wilaya_name' => $this->yalidineService->getWilayaNameById($id),
                'communes' => $communes,
                'centers' => $centers,
            ]);
        }

        $wilayas = $this->yalidineService->getWilayas();

        return response()->json([
            'status' => 'success',
            'wilayas' => $wilayas,
        ]);
    }

    /**
     * Calculate dynamic delivery fee between seller/product origin and destination.
     *
     * POST /api/v1.0/yalidine/calculate-fee
     */
    public function calculateFee(Request $request): JsonResponse
    {
        $explicitFrom = $request->input('from_wilaya_id') ?? $request->input('from_wilaya');
        $itemId = $request->input('item_id') ?? $request->input('product_id');
        $vendorId = $request->input('vendor_id');

        $fromWilaya = $this->yalidineService->resolveItemFromWilaya(
            $itemId ? (int) $itemId : null,
            $vendorId ? (int) $vendorId : null,
            $explicitFrom
        );

        $toWilaya = $request->input('to_wilaya_id')
            ?? $request->input('shipping_city_id')
            ?? $request->input('shipping_city')
            ?? $request->input('shipping_state')
            ?? 16;

        $deliveryType = $request->input('delivery_type');
        if (empty($deliveryType)) {
            $isStopDesk = filter_var($request->input('is_stop_desk', false), FILTER_VALIDATE_BOOLEAN);
            $deliveryType = $isStopDesk ? 'stop_desk' : 'home';
        }

        $weight = (float) ($request->input('weight', 1));

        $feeData = $this->yalidineService->calculateDeliveryFee($fromWilaya, $toWilaya, $deliveryType, $weight);

        // Fetch available Stop Desk centers in destination wilaya
        $toWilayaId = $feeData['to_wilaya_id'];
        $communeId = $request->input('to_commune_id') ?? $request->query('to_commune_id');
        $communeName = $request->input('to_commune_name') ?? $request->query('to_commune_name');
        $centers = $this->yalidineService->getCenters($toWilayaId, $communeId, $communeName);

        $itemPrice = (float) ($request->input('item_price') ?? $request->input('sub_total') ?? $request->input('total_price') ?? 0);
        $totalPrice = $itemPrice + (float) $feeData['delivery_fee'];

        return response()->json([
            'status' => 'success',
            'delivery_type' => $feeData['delivery_type'],
            'delivery_fee' => (float) $feeData['delivery_fee'],
            'home_fee' => (float) $feeData['home_fee'],
            'desk_fee' => (float) $feeData['desk_fee'],
            'from_wilaya_id' => $feeData['from_wilaya_id'],
            'from_wilaya_name' => $feeData['from_wilaya_name'],
            'to_wilaya_id' => $feeData['to_wilaya_id'],
            'to_wilaya_name' => $feeData['to_wilaya_name'],
            'centers' => $centers,
            'item_price' => $itemPrice,
            'total_price' => $totalPrice,
            'currency' => 'DA',
            'is_stub' => $feeData['is_stub'],
        ]);
    }

    /**
     * Create / Retry Yalidine parcel for an order.
     *
     * POST /api/v1.0/yalidine/create-parcel/{orderId}
     */
    public function createParcel(Request $request, $orderId): JsonResponse
    {
        $order = Order::with(['shippingAndBilling', 'orderItems.item', 'user', 'vendorTransaction'])
            ->find($orderId);

        if (!$order) {
            return response()->json([
                'status' => 'error',
                'message' => __('Order not found.'),
            ], 404);
        }

        $dzshipService = app(\App\Services\DzshipYalidineService::class);
        $result = $dzshipService->createShipment($order);

        if (empty($result['success'])) {
            return response()->json([
                'status' => 'error',
                'message' => $result['error'] ?? __('Failed to create Yalidine parcel.'),
            ], 400);
        }

        return response()->json([
            'status' => 'success',
            'message' => __('Yalidine parcel generated successfully.'),
            'tracking' => $result['tracking'],
            'parcel_id' => $result['parcel_id'],
            'label_url' => $result['label_url'] ?? null,
            'parcel_status' => $result['status'] ?? 'dispatched',
        ]);
    }
}
