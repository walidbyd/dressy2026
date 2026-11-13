<?php

namespace Modules\StoreFront\VendorPanel\Http\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Modules\StoreFront\VendorPanel\Entities\Order;

class YalidineService
{
    protected string $apiId;

    protected string $apiToken;

    protected string $apiUrl;

    protected bool $stubMode;

    public function __construct()
    {
        $this->apiId = (string) config('services.yalidine.api_id', env('YALIDINE_API_ID', ''));
        $this->apiToken = (string) config('services.yalidine.api_token', env('YALIDINE_API_TOKEN', ''));
        $this->apiUrl = rtrim((string) config('services.yalidine.api_url', env('YALIDINE_API_URL', 'https://api.yalidine.app/v1')), '/');
        $this->stubMode = class_exists(WalletService::class) 
            ? WalletService::isYalidineStubMode() 
            : (bool) config('services.yalidine.stub_mode', env('YALIDINE_STUB_MODE', false));

        // Fallback to stub mode if credentials are missing
        if (empty($this->apiId) || empty($this->apiToken)) {
            $this->stubMode = true;
        }
    }

    public function isStubMode(): bool
    {
        return $this->stubMode;
    }

    /**
     * Calculate dynamic Yalidine delivery fee based on origin and destination Wilayas.
     *
     * @param  int|string  $fromWilaya
     * @param  int|string  $toWilaya
     * @param  bool  $isStopDesk
     * @param  float|int  $weight
     * @return array
     */
    public function calculateDeliveryFee($fromWilaya, $toWilaya, bool $isStopDesk = false, $weight = 1): array
    {
        $fromId = $this->normalizeWilayaId($fromWilaya);
        $toId = $this->normalizeWilayaId($toWilaya);
        $deskKey = $isStopDesk ? 'desk' : 'home';

        $cacheKey = "yalidine_fee_{$fromId}_{$toId}_{$deskKey}";

        return Cache::remember($cacheKey, 21600, function () use ($fromId, $toId, $isStopDesk, $weight) {
            // Live API check if not in stub mode
            if (!$this->stubMode && !empty($this->apiId) && !empty($this->apiToken)) {
                try {
                    $endpoint = $this->apiUrl . '/deliveryfees/';
                    $response = Http::withHeaders([
                        'X-API-ID' => $this->apiId,
                        'X-API-TOKEN' => $this->apiToken,
                        'Accept' => 'application/json',
                    ])->timeout(10)->get($endpoint, [
                        'from_wilaya_id' => $fromId,
                        'to_wilaya_id' => $toId,
                        'weight' => $weight,
                    ]);

                    if ($response->successful()) {
                        $data = $response->json();
                        // Yalidine delivery fees response structure:
                        // {"from_wilaya_id":16,"to_wilaya_id":31,"home_fee":600,"desk_fee":500,...} or similar
                        if (is_array($data)) {
                            $liveFee = null;
                            if ($isStopDesk && isset($data['desk_fee'])) {
                                $liveFee = (float) $data['desk_fee'];
                            } elseif (!$isStopDesk && isset($data['home_fee'])) {
                                $liveFee = (float) $data['home_fee'];
                            } elseif (isset($data['fee']) || isset($data['price'])) {
                                $liveFee = (float) ($data['fee'] ?? $data['price']);
                            }

                            if ($liveFee !== null && $liveFee > 0) {
                                return [
                                    'status' => 'success',
                                    'delivery_fee' => $liveFee,
                                    'is_stop_desk' => $isStopDesk,
                                    'from_wilaya_id' => $fromId,
                                    'to_wilaya_id' => $toId,
                                    'currency' => 'DA',
                                    'is_stub' => false,
                                ];
                            }
                        }
                    }
                } catch (\Exception $e) {
                    Log::warning("Yalidine Live Delivery Fee API failed, falling back to Algerian fee matrix: " . $e->getMessage());
                }
            }

            // Fallback / Stub fee matrix for Algeria:
            // 1. South / Saharan Wilayas
            $southWilayas = [11, 30, 33, 37, 39, 47, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58];
            $isSouth = in_array($fromId, $southWilayas) || in_array($toId, $southWilayas);

            // 2. Intra-wilaya delivery (same wilaya)
            $isIntraWilaya = ($fromId === $toId);

            if ($isIntraWilaya) {
                $fee = $isStopDesk ? 300.00 : 400.00;
            } elseif ($isSouth) {
                $fee = $isStopDesk ? 750.00 : 850.00;
            } else {
                // Standard Inter-wilaya (North / Center / Plateaux)
                $fee = $isStopDesk ? 500.00 : 600.00;
            }

            return [
                'status' => 'success',
                'delivery_fee' => (float) $fee,
                'is_stop_desk' => $isStopDesk,
                'from_wilaya_id' => $fromId,
                'to_wilaya_id' => $toId,
                'currency' => 'DA',
                'is_stub' => true,
            ];
        });
    }

    /**
     * Normalize wilaya input (id, code, or name) to official wilaya ID (1..58).
     *
     * @param  mixed  $wilaya
     * @return int
     */
    public function normalizeWilayaId($wilaya): int
    {
        if (is_numeric($wilaya)) {
            $id = (int) $wilaya;
            return ($id >= 1 && $id <= 58) ? $id : 16;
        }

        if (is_string($wilaya)) {
            $trimmed = trim($wilaya);
            if (preg_match('/^0*([1-9]|[1-5][0-9])\b/', $trimmed, $matches)) {
                $id = (int) $matches[1];
                if ($id >= 1 && $id <= 58) {
                    return $id;
                }
            }

            $wilayaMap = [
                'adrar' => 1, 'chlef' => 2, 'laghouat' => 3, 'oum el bouaghi' => 4, 'batna' => 5,
                'bejaia' => 6, 'béjaïa' => 6, 'biskra' => 7, 'bechar' => 8, 'béchar' => 8,
                'blida' => 9, 'bouira' => 10, 'tamanrasset' => 11, 'tebessa' => 12, 'tébessa' => 12,
                'tlemcen' => 13, 'tiaret' => 14, 'tizi ouzou' => 15, 'alger' => 16, 'algiers' => 16,
                'djelfa' => 17, 'jijel' => 18, 'setif' => 19, 'sétif' => 19, 'saida' => 20,
                'saïda' => 20, 'skikda' => 21, 'sidi bel abbes' => 22, 'sidi bel abbès' => 22,
                'annaba' => 23, 'guelma' => 24, 'constantine' => 25, 'medea' => 26, 'médéa' => 26,
                'mostaganem' => 27, 'msila' => 28, "m'sila" => 28, 'mascara' => 29, 'ouargla' => 30,
                'oran' => 31, 'el bayadh' => 32, 'illizi' => 33, 'bordj bou arreridj' => 34,
                'boumerdes' => 35, 'boumerdès' => 35, 'el tarf' => 36, 'tindouf' => 37,
                'tissemsilt' => 38, 'el oued' => 39, 'khenchela' => 40, 'souk ahras' => 41,
                'tipaza' => 42, 'mila' => 43, 'ain defla' => 44, 'aïn defla' => 44, 'naama' => 45,
                'naâma' => 45, 'ain temouchent' => 46, 'aïn témouchent' => 46, 'ghardaia' => 47,
                'ghardaïa' => 47, 'relizane' => 48, 'timimoun' => 49, 'bordj badji mokhtar' => 50,
                'ouled djellal' => 51, 'beni abbes' => 52, 'béni abbès' => 52, 'in salah' => 53,
                'in guezzam' => 54, 'touggourt' => 55, 'djanet' => 56, 'el mghair' => 57,
                "el m'ghair" => 57, 'el meniaa' => 58,
            ];

            $cleanName = strtolower(preg_replace('/[^a-zA-Z\s\']/', '', $trimmed));
            $cleanName = trim($cleanName);
            if (isset($wilayaMap[$cleanName])) {
                return $wilayaMap[$cleanName];
            }
        }

        return 16; // Default to Alger
    }

    /**
     * Create a Yalidine parcel for the specified order.
     *
     * @param  Order  $order
     * @return array
     */
    public function createParcelForOrder(Order $order): array
    {
        $shipping = $order->shippingAndBilling;
        $orderItems = $order->orderItems;

        $itemsSummaryList = [];
        if ($orderItems) {
            foreach ($orderItems as $item) {
                $itemsSummaryList[] = ($item->item_name ?? 'Item').' (x'.($item->quantity ?? 1).')';
            }
        }
        $productList = ! empty($itemsSummaryList) ? implode(', ', $itemsSummaryList) : 'Order '.$order->order_code;
        $productList = Str::limit($productList, 180);

        $codAmount = (float) ($order->vendorTransaction?->payment_amount ?? $order->total_price ?? $order->total_amount ?? 0);

        $firstName = $shipping->shipping_first_name ?? 'Customer';
        $lastName = $shipping->shipping_last_name ?? '';
        $phone = $shipping->shipping_phone_no ?? '';
        $address = $shipping->shipping_address ?? '';
        $wilaya = $shipping->shipping_state ?? $shipping->shipping_city ?? 'Alger';
        $commune = $shipping->shipping_city ?? $shipping->shipping_state ?? 'Alger';

        $parcelData = [
            'order_id' => (string) $order->order_code,
            'firstname' => (string) $firstName,
            'familyname' => (string) $lastName,
            'contact_phone' => (string) $phone,
            'address' => (string) $address,
            'to_commune_name' => (string) $commune,
            'to_wilaya_name' => (string) $wilaya,
            'product_list' => (string) $productList,
            'price' => $codAmount,
            'freeshipping' => false,
            'is_stopdesk' => false,
            'has_exchange' => 0,
        ];

        if ($this->stubMode) {
            Log::info('Yalidine [STUB MODE] Creating parcel payload:', [
                'order_id' => $order->id,
                'order_code' => $order->order_code,
                'payload' => $parcelData,
            ]);

            $stubTracking = 'STUB-'.strtoupper(Str::random(10));
            $stubParcelId = 'PARCEL-'.strtoupper(Str::random(8));

            return [
                'success' => true,
                'tracking' => $stubTracking,
                'parcel_id' => $stubParcelId,
                'status' => 'dispatched',
                'label_url' => null,
                'is_stub' => true,
            ];
        }

        return $this->sendCreateParcelRequest([$parcelData], (string) $order->order_code);
    }

    /**
     * Send create parcel HTTP request to Yalidine API.
     *
     * @param  array  $parcels
     * @param  string  $orderCode
     * @return array
     */
    protected function sendCreateParcelRequest(array $parcels, string $orderCode): array
    {
        try {
            $endpoint = $this->apiUrl.'/parcels/';

            $response = Http::withHeaders([
                'X-API-ID' => $this->apiId,
                'X-API-TOKEN' => $this->apiToken,
                'Content-Type' => 'application/json',
                'Accept' => 'application/json',
            ])->timeout(20)->post($endpoint, $parcels);

            $body = $response->json();

            Log::info('Yalidine API Response:', [
                'status' => $response->status(),
                'body' => $body,
            ]);

            if ($response->successful() && is_array($body)) {
                // Yalidine responses can be keyed by order_id: {"ORD-123": {"success": true, "tracking": "..."}}
                if (isset($body[$orderCode])) {
                    $item = $body[$orderCode];
                    if (! empty($item['success']) && ! empty($item['tracking'])) {
                        return [
                            'success' => true,
                            'tracking' => (string) $item['tracking'],
                            'parcel_id' => (string) ($item['parcel_id'] ?? $item['tracking']),
                            'status' => 'dispatched',
                            'label_url' => $item['label'] ?? null,
                            'is_stub' => false,
                        ];
                    }
                    $errorMsg = $item['error'] ?? $item['message'] ?? 'Yalidine rejected parcel creation for this order.';

                    return [
                        'success' => false,
                        'error' => is_array($errorMsg) ? implode(', ', $errorMsg) : (string) $errorMsg,
                    ];
                }

                // Or a list of items: [{"order_id": "...", "tracking": "...", "success": true}]
                if (isset($body[0])) {
                    foreach ($body as $item) {
                        if (isset($item['order_id']) && $item['order_id'] == $orderCode) {
                            if (! empty($item['tracking'])) {
                                return [
                                    'success' => true,
                                    'tracking' => (string) $item['tracking'],
                                    'parcel_id' => (string) ($item['parcel_id'] ?? $item['tracking']),
                                    'status' => 'dispatched',
                                    'label_url' => $item['label'] ?? null,
                                    'is_stub' => false,
                                ];
                            }
                        }
                    }
                }

                // If response has top-level tracking:
                if (! empty($body['tracking'])) {
                    return [
                        'success' => true,
                        'tracking' => (string) $body['tracking'],
                        'parcel_id' => (string) ($body['parcel_id'] ?? $body['tracking']),
                        'status' => 'dispatched',
                        'label_url' => $body['label'] ?? null,
                        'is_stub' => false,
                    ];
                }
            }

            // Extract error message
            $errorMsg = 'Yalidine API request failed ('.$response->status().').';
            if (is_array($body)) {
                if (isset($body['message'])) {
                    $errorMsg = is_array($body['message']) ? implode(', ', $body['message']) : $body['message'];
                } elseif (isset($body['error'])) {
                    $errorMsg = is_array($body['error']) ? implode(', ', $body['error']) : $body['error'];
                } elseif (isset($body[$orderCode]['error'])) {
                    $errorMsg = is_array($body[$orderCode]['error']) ? implode(', ', $body[$orderCode]['error']) : $body[$orderCode]['error'];
                }
            }

            return [
                'success' => false,
                'error' => $errorMsg,
            ];
        } catch (\Exception $e) {
            Log::error('Yalidine Exception: '.$e->getMessage());

            return [
                'success' => false,
                'error' => 'Yalidine connection failed: '.$e->getMessage(),
            ];
        }
    }
}
