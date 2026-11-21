<?php

namespace App\Services;

use Carbon\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Modules\StoreFront\VendorPanel\Entities\Order;

class YalidineService
{
    protected string $apiId = '';

    protected string $apiToken = '';

    protected string $apiUrl = 'https://api.yalidine.app/v1';

    protected bool $stubMode = false;

    public function __construct()
    {
        $this->resolveCredentials();
    }

    /**
     * Resolve API credentials from DB settings or config/env.
     */
    protected function resolveCredentials(): void
    {
        // 1. Try psx_delivery_settings (Admin Delivery Settings)
        try {
            $deliverySetting = \App\Models\DeliverySetting::first();
            if ($deliverySetting) {
                if (!empty($deliverySetting->api_id)) {
                    $this->apiId = trim((string) $deliverySetting->api_id);
                }
                if (!empty($deliverySetting->api_token)) {
                    $this->apiToken = trim((string) $deliverySetting->api_token);
                }
                if (!empty($deliverySetting->api_base_url)) {
                    $this->apiUrl = rtrim(trim((string) $deliverySetting->api_base_url), '/');
                }
                if (!$deliverySetting->is_enabled || $deliverySetting->environment === 'sandbox') {
                    $this->stubMode = true;
                }
            }
        } catch (\Throwable $e) {
            // Ignore DB errors during early bootstrapping
        }

        // 2. Try psx_backend_settings
        try {
            $backendSetting = DB::table('psx_backend_settings')->first();
            if ($backendSetting) {
                if (!empty($backendSetting->yalidine_api_id)) {
                    $this->apiId = trim((string) $backendSetting->yalidine_api_id);
                }
                if (!empty($backendSetting->yalidine_api_token)) {
                    $this->apiToken = trim((string) $backendSetting->yalidine_api_token);
                }
            }
        } catch (\Throwable $e) {
            // Ignore DB errors during early bootstrapping
        }

        // 2. Try psx_settings (setting_env = 'yalidine_config') if still empty
        if (empty($this->apiId) || empty($this->apiToken)) {
            try {
                $settingRow = DB::table('psx_settings')->where('setting_env', 'yalidine_config')->first();
                if ($settingRow && !empty($settingRow->setting)) {
                    $json = json_decode($settingRow->setting, true);
                    if (is_array($json)) {
                        $this->apiId = $this->apiId ?: ($json['api_id'] ?? '');
                        $this->apiToken = $this->apiToken ?: ($json['api_token'] ?? '');
                    }
                }
            } catch (\Throwable $e) {
                // Ignore
            }
        }

        // 3. Fallback to config / .env
        if (empty($this->apiId)) {
            $this->apiId = (string) config('services.yalidine.api_id', env('YALIDINE_API_ID', ''));
        }
        if (empty($this->apiToken)) {
            $this->apiToken = (string) config('services.yalidine.api_token', env('YALIDINE_API_TOKEN', ''));
        }

        $this->apiUrl = rtrim((string) config('services.yalidine.api_url', env('YALIDINE_API_URL', 'https://api.yalidine.app/v1')), '/');

        // Check if stub mode is explicitly enabled or credentials missing
        $configuredStub = (bool) config('services.yalidine.stub_mode', env('YALIDINE_STUB_MODE', false));
        $this->stubMode = $configuredStub || empty($this->apiId) || empty($this->apiToken);
    }

    public function isStubMode(): bool
    {
        return $this->stubMode;
    }

    public function getApiId(): string
    {
        return $this->apiId;
    }

    public function getApiToken(): string
    {
        return $this->apiToken;
    }

    /**
     * Get official 58 Wilayas (cached 24h).
     *
     * @return array
     */
    public function getWilayas(): array
    {
        return Cache::remember('yalidine_wilayas_v1', 86400, function () {
            if (!$this->stubMode) {
                try {
                    $response = Http::withHeaders([
                        'X-API-ID' => $this->apiId,
                        'X-API-TOKEN' => $this->apiToken,
                        'Accept' => 'application/json',
                    ])->timeout(10)->get("{$this->apiUrl}/wilayas/");

                    if ($response->successful()) {
                        $json = $response->json();
                        $data = $json['data'] ?? $json;
                        if (is_array($data) && !empty($data)) {
                            return array_map(function ($w) {
                                return [
                                    'id' => (int) ($w['id'] ?? $w['wilaya_id'] ?? 0),
                                    'code' => sprintf('%02d', (int) ($w['id'] ?? $w['wilaya_id'] ?? 0)),
                                    'name' => (string) ($w['name'] ?? $w['wilaya_name'] ?? ''),
                                    'is_deliverable' => (bool) ($w['is_deliverable'] ?? true),
                                ];
                            }, $data);
                        }
                    }
                } catch (\Throwable $e) {
                    Log::warning('Yalidine getWilayas live API call failed, falling back to local list: ' . $e->getMessage());
                }
            }

            // Fallback list of Algeria's 58 Wilayas
            return $this->getFallbackWilayas();
        });
    }

    /**
     * Get Communes for a specific Wilaya (cached 24h).
     *
     * @param int|string $wilayaId
     * @return array
     */
    public function getCommunes($wilayaId): array
    {
        $id = $this->normalizeWilayaId($wilayaId);
        $cacheKey = "yalidine_communes_w_{$id}";

        return Cache::remember($cacheKey, 86400, function () use ($id) {
            if (!$this->stubMode) {
                try {
                    $response = Http::withHeaders([
                        'X-API-ID' => $this->apiId,
                        'X-API-TOKEN' => $this->apiToken,
                        'Accept' => 'application/json',
                    ])->timeout(10)->get("{$this->apiUrl}/communes/", ['wilaya_id' => $id]);

                    if ($response->successful()) {
                        $json = $response->json();
                        $data = $json['data'] ?? $json;
                        if (is_array($data) && !empty($data)) {
                            return array_map(function ($c) use ($id) {
                                return [
                                    'id' => (int) ($c['id'] ?? $c['commune_id'] ?? 0),
                                    'wilaya_id' => (int) ($c['wilaya_id'] ?? $id),
                                    'name' => (string) ($c['name'] ?? $c['commune_name'] ?? ''),
                                    'has_stop_desk' => (bool) ($c['has_stop_desk'] ?? false),
                                    'is_deliverable' => (bool) ($c['is_deliverable'] ?? true),
                                ];
                            }, $data);
                        }
                    }
                } catch (\Throwable $e) {
                    Log::warning("Yalidine getCommunes live API call failed for wilaya {$id}: " . $e->getMessage());
                }
            }

            // Fallback from psx_location_townships if present
            try {
                $townships = DB::table('psx_location_townships')
                    ->where('location_city_id', $id)
                    ->get();
                if ($townships->isNotEmpty()) {
                    return $townships->map(function ($t) use ($id) {
                        return [
                            'id' => (int) $t->id,
                            'wilaya_id' => $id,
                            'name' => (string) $t->name,
                            'has_stop_desk' => true,
                            'is_deliverable' => true,
                        ];
                    })->toArray();
                }
            } catch (\Throwable $e) {
                // Ignore
            }

            // Default commune with wilaya name
            $wilayaName = $this->getWilayaNameById($id);
            return [
                [
                    'id' => $id * 100 + 1,
                    'wilaya_id' => $id,
                    'name' => $wilayaName,
                    'has_stop_desk' => true,
                    'is_deliverable' => true,
                ],
            ];
        });
    }

    /**
     * Get Yalidine Stop Desk Centers for a specific Wilaya (cached 24h).
     *
     * @param int|string $wilayaId
     * @return array
     */
    public function getCenters($wilayaId): array
    {
        $id = $this->normalizeWilayaId($wilayaId);
        $cacheKey = "yalidine_centers_w_{$id}";

        return Cache::remember($cacheKey, 86400, function () use ($id) {
            if (!$this->stubMode) {
                try {
                    $response = Http::withHeaders([
                        'X-API-ID' => $this->apiId,
                        'X-API-TOKEN' => $this->apiToken,
                        'Accept' => 'application/json',
                    ])->timeout(10)->get("{$this->apiUrl}/centers/", ['wilaya_id' => $id]);

                    if ($response->successful()) {
                        $json = $response->json();
                        $data = $json['data'] ?? $json;
                        if (is_array($data) && !empty($data)) {
                            return array_map(function ($center) use ($id) {
                                return [
                                    'center_id' => (int) ($center['center_id'] ?? $center['id'] ?? 0),
                                    'name' => (string) ($center['name'] ?? $center['center_name'] ?? 'Centre Yalidine'),
                                    'address' => (string) ($center['address'] ?? ''),
                                    'commune_name' => (string) ($center['commune_name'] ?? ''),
                                    'wilaya_id' => (int) ($center['wilaya_id'] ?? $id),
                                ];
                            }, $data);
                        }
                    }
                } catch (\Throwable $e) {
                    Log::warning("Yalidine getCenters live API call failed for wilaya {$id}: " . $e->getMessage());
                }
            }

            // Fallback default center for that Wilaya
            $wilayaName = $this->getWilayaNameById($id);
            return [
                [
                    'center_id' => $id * 1000 + 1,
                    'name' => "Centre Yalidine - {$wilayaName}",
                    'address' => "Agence Principale Yalidine, {$wilayaName}",
                    'commune_name' => $wilayaName,
                    'wilaya_id' => $id,
                ],
            ];
        });
    }

    /**
     * Calculate dynamic delivery fee between origin and destination wilayas.
     *
     * @param int|string $fromWilaya
     * @param int|string $toWilaya
     * @param string $deliveryType 'home' or 'stop_desk'
     * @param float|int $weight
     * @return array
     */
    public function calculateDeliveryFee($fromWilaya, $toWilaya, string $deliveryType = 'home', $weight = 1): array
    {
        $fromId = $this->normalizeWilayaId($fromWilaya);
        $toId = $this->normalizeWilayaId($toWilaya);
        $isStopDesk = ($deliveryType === 'stop_desk');

        $cacheKey = "yalidine_fee_v2_{$fromId}_{$toId}";

        $rates = Cache::remember($cacheKey, 21600, function () use ($fromId, $toId, $weight) {
            $liveHomeFee = null;
            $liveDeskFee = null;

            if (!$this->stubMode) {
                try {
                    $response = Http::withHeaders([
                        'X-API-ID' => $this->apiId,
                        'X-API-TOKEN' => $this->apiToken,
                        'Accept' => 'application/json',
                    ])->timeout(10)->get("{$this->apiUrl}/deliveryfees/", [
                        'from_wilaya_id' => $fromId,
                        'to_wilaya_id' => $toId,
                        'weight' => $weight,
                    ]);

                    if ($response->successful()) {
                        $data = $response->json();
                        if (is_array($data)) {
                            if (isset($data['home_fee'])) {
                                $liveHomeFee = (float) $data['home_fee'];
                            }
                            if (isset($data['desk_fee'])) {
                                $liveDeskFee = (float) $data['desk_fee'];
                            }
                        }
                    }
                } catch (\Throwable $e) {
                    Log::warning("Yalidine calculateDeliveryFee API failed: " . $e->getMessage());
                }
            }

            // Fallback matrix in DZD
            $southWilayas = [11, 30, 33, 37, 39, 47, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58];
            $isSouth = in_array($fromId, $southWilayas) || in_array($toId, $southWilayas);
            $isIntra = ($fromId === $toId);

            if ($isIntra) {
                $defaultHome = 400.00;
                $defaultDesk = 300.00;
            } elseif ($isSouth) {
                $defaultHome = 850.00;
                $defaultDesk = 750.00;
            } else {
                $defaultHome = 600.00;
                $defaultDesk = 500.00;
            }

            return [
                'home_fee' => ($liveHomeFee !== null && $liveHomeFee > 0) ? $liveHomeFee : $defaultHome,
                'desk_fee' => ($liveDeskFee !== null && $liveDeskFee > 0) ? $liveDeskFee : $defaultDesk,
                'is_stub' => ($liveHomeFee === null),
            ];
        });

        $chosenFee = $isStopDesk ? $rates['desk_fee'] : $rates['home_fee'];

        return [
            'status' => 'success',
            'delivery_type' => $isStopDesk ? 'stop_desk' : 'home',
            'delivery_fee' => (float) $chosenFee,
            'home_fee' => (float) $rates['home_fee'],
            'desk_fee' => (float) $rates['desk_fee'],
            'from_wilaya_id' => $fromId,
            'from_wilaya_name' => $this->getWilayaNameById($fromId),
            'to_wilaya_id' => $toId,
            'to_wilaya_name' => $this->getWilayaNameById($toId),
            'currency' => 'DA',
            'is_stub' => $rates['is_stub'] ?? false,
        ];
    }

    /**
     * Create a Yalidine parcel for the order upon seller approval or manual retry.
     *
     * @param Order $order
     * @return array
     */
    public function createParcelForOrder(Order $order): array
    {
        $shipping = $order->shippingAndBilling;
        $orderItems = $order->orderItems;

        $itemsSummaryList = [];
        if ($orderItems) {
            foreach ($orderItems as $item) {
                $name = $item->item_name ?? ($item->item?->title ?? 'Article');
                $qty = $item->quantity ?? 1;
                $itemsSummaryList[] = "{$name} (x{$qty})";
            }
        }
        $productList = !empty($itemsSummaryList) ? implode(', ', $itemsSummaryList) : "Commande #{$order->order_code}";
        $productList = Str::limit($productList, 180);

        $codAmount = (float) ($order->total_price ?? $order->vendorTransaction?->payment_amount ?? 0);

        $firstName = $shipping?->shipping_first_name ?: ($order->user?->name ?: 'Client');
        $lastName = $shipping?->shipping_last_name ?: '';
        $phone = $shipping?->shipping_phone_no ?: ($order->user?->user_phone ?: '');
        $address = $shipping?->shipping_address ?: 'Livraison';

        $isStopDesk = ($order->delivery_type === 'stop_desk');
        $toWilayaId = $order->to_wilaya_id ?: $this->normalizeWilayaId($shipping?->shipping_state ?: $shipping?->shipping_city);
        $toWilayaName = $this->getWilayaNameById($toWilayaId);
        $toCommuneName = $order->to_commune_name ?: ($shipping?->shipping_city ?: $toWilayaName);

        $parcelPayload = [
            'order_id' => (string) $order->order_code,
            'firstname' => (string) $firstName,
            'familyname' => (string) $lastName,
            'contact_phone' => (string) $phone,
            'address' => (string) $address,
            'to_commune_name' => (string) $toCommuneName,
            'to_wilaya_name' => (string) $toWilayaName,
            'product_list' => (string) $productList,
            'price' => $codAmount,
            'freeshipping' => false,
            'is_stopdesk' => $isStopDesk,
            'has_exchange' => 0,
        ];

        if ($isStopDesk && !empty($order->yalidine_stop_desk_id)) {
            $parcelPayload['stopdesk_id'] = (int) $order->yalidine_stop_desk_id;
        }

        if ($this->stubMode) {
            Log::info('Yalidine [STUB MODE] Creating parcel payload:', [
                'order_id' => $order->id,
                'order_code' => $order->order_code,
                'payload' => $parcelPayload,
            ]);

            $stubTracking = 'yal-' . strtoupper(Str::random(8));
            $stubParcelId = 'PARCEL-' . strtoupper(Str::random(6));
            $stubLabelUrl = "https://api.yalidine.app/v1/parcels/print/?tracking={$stubTracking}";

            $order->yalidine_tracking = $stubTracking;
            $order->yalidine_parcel_id = $stubParcelId;
            $order->yalidine_label_url = $stubLabelUrl;
            $order->yalidine_parcel_status = 'dispatched';
            $order->yalidine_status = 'dispatched';
            $order->save();

            return [
                'success' => true,
                'tracking' => $stubTracking,
                'parcel_id' => $stubParcelId,
                'label_url' => $stubLabelUrl,
                'status' => 'dispatched',
                'is_stub' => true,
            ];
        }

        try {
            $endpoint = "{$this->apiUrl}/parcels/";
            $response = Http::withHeaders([
                'X-API-ID' => $this->apiId,
                'X-API-TOKEN' => $this->apiToken,
                'Content-Type' => 'application/json',
                'Accept' => 'application/json',
            ])->timeout(20)->post($endpoint, [$parcelPayload]);

            $body = $response->json();
            Log::info("Yalidine Create Parcel Response (Code {$order->order_code}):", [
                'status' => $response->status(),
                'body' => $body,
            ]);

            if ($response->successful() && is_array($body)) {
                $orderCode = (string) $order->order_code;
                $parcelInfo = null;

                if (isset($body[$orderCode])) {
                    $parcelInfo = $body[$orderCode];
                } elseif (isset($body[0])) {
                    foreach ($body as $b) {
                        if (isset($b['order_id']) && (string) $b['order_id'] === $orderCode) {
                            $parcelInfo = $b;
                            break;
                        }
                    }
                } elseif (!empty($body['tracking'])) {
                    $parcelInfo = $body;
                }

                if ($parcelInfo && (!empty($parcelInfo['tracking']) || !empty($parcelInfo['success']))) {
                    $tracking = (string) ($parcelInfo['tracking'] ?? '');
                    $parcelId = (string) ($parcelInfo['parcel_id'] ?? $tracking);
                    $labelUrl = (string) ($parcelInfo['label'] ?? $parcelInfo['label_url'] ?? "https://api.yalidine.app/v1/parcels/print/?tracking={$tracking}");

                    $order->yalidine_tracking = $tracking;
                    $order->yalidine_parcel_id = $parcelId;
                    $order->yalidine_label_url = $labelUrl;
                    $order->yalidine_parcel_status = 'dispatched';
                    $order->yalidine_status = 'dispatched';
                    $order->save();

                    return [
                        'success' => true,
                        'tracking' => $tracking,
                        'parcel_id' => $parcelId,
                        'label_url' => $labelUrl,
                        'status' => 'dispatched',
                        'is_stub' => false,
                    ];
                }

                $err = $parcelInfo['error'] ?? $parcelInfo['message'] ?? ($body['message'] ?? 'Yalidine rejected parcel creation.');
                return [
                    'success' => false,
                    'error' => is_array($err) ? implode(', ', $err) : (string) $err,
                ];
            }

            return [
                'success' => false,
                'error' => "Yalidine request failed with HTTP {$response->status()}",
            ];
        } catch (\Throwable $e) {
            Log::error('Yalidine Exception: ' . $e->getMessage());
            return [
                'success' => false,
                'error' => 'Connection to Yalidine API failed: ' . $e->getMessage(),
            ];
        }
    }

    /**
     * Map any wilaya input (id, code, name) to official Wilaya ID 1..58.
     *
     * @param mixed $wilaya
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

        return 16; // Alger
    }

    /**
     * Get official name of Wilaya by ID.
     */
    public function getWilayaNameById(int $wilayaId): string
    {
        $names = [
            1 => 'Adrar', 2 => 'Chlef', 3 => 'Laghouat', 4 => 'Oum El Bouaghi', 5 => 'Batna',
            6 => 'Béjaïa', 7 => 'Biskra', 8 => 'Béchar', 9 => 'Blida', 10 => 'Bouira',
            11 => 'Tamanrasset', 12 => 'Tébessa', 13 => 'Tlemcen', 14 => 'Tiaret', 15 => 'Tizi Ouzou',
            16 => 'Alger', 17 => 'Djelfa', 18 => 'Jijel', 19 => 'Sétif', 20 => 'Saïda',
            21 => 'Skikda', 22 => 'Sidi Bel Abbès', 23 => 'Annaba', 24 => 'Guelma', 25 => 'Constantine',
            26 => 'Médéa', 27 => 'Mostaganem', 28 => "M'Sila", 29 => 'Mascara', 30 => 'Ouargla',
            31 => 'Oran', 32 => 'El Bayadh', 33 => 'Illizi', 34 => 'Bordj Bou Arreridj', 35 => 'Boumerdès',
            36 => 'El Tarf', 37 => 'Tindouf', 38 => 'Tissemsilt', 39 => 'El Oued', 40 => 'Khenchela',
            41 => 'Souk Ahras', 42 => 'Tipaza', 43 => 'Mila', 44 => 'Aïn Defla', 45 => 'Naâma',
            46 => 'Aïn Témouchent', 47 => 'Ghardaïa', 48 => 'Relizane', 49 => 'Timimoun', 50 => 'Bordj Badji Mokhtar',
            51 => 'Ouled Djellal', 52 => 'Béni Abbès', 53 => 'In Salah', 54 => 'In Guezzam', 55 => 'Touggourt',
            56 => 'Djanet', 57 => "El M'Ghair", 58 => 'El Meniaa'
        ];

        return $names[$wilayaId] ?? "Wilaya {$wilayaId}";
    }

    /**
     * Full list of 58 Wilayas with code and name.
     */
    protected function getFallbackWilayas(): array
    {
        $wilayas = [];
        for ($i = 1; $i <= 58; $i++) {
            $name = $this->getWilayaNameById($i);
            $wilayas[] = [
                'id' => $i,
                'code' => sprintf('%02d', $i),
                'name' => sprintf('%02d - %s', $i, $name),
                'clean_name' => $name,
                'is_deliverable' => true,
            ];
        }
        return $wilayas;
    }
}
