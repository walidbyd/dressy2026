<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Modules\StoreFront\VendorPanel\Entities\Order;

/**
 * Dressy Yalidine Shipping Service backed by DZBuild dzship (https://freeship.dzbuild.com).
 *
 * Strictly uses courier "yalidine" (or "sandbox" / local config fallback while YALIDINE_STUB_MODE=true).
 * Buyers only need Recipient Name, Phone, Wilaya, Commune (or Stop-Desk), and Delivery Type.
 */
class DzshipYalidineService
{
    public const COURIER_YALIDINE = 'yalidine';
    public const COURIER_SANDBOX = 'sandbox';
    public const CACHE_TTL_SECONDS = 604800; // 7 days

    protected string $baseUrl;
    protected ?string $apiId;
    protected ?string $apiToken;
    protected bool $stubMode;

    public function __construct()
    {
        $this->baseUrl = rtrim((string) config('services.yalidine.dzship_url', config('yalidine_rates.base_url', 'https://freeship.dzbuild.com')), '/');
        $this->apiId = config('services.yalidine.api_id');
        $this->apiToken = config('services.yalidine.api_token');
        $configuredStub = filter_var(config('services.yalidine.stub_mode', config('yalidine_rates.stub_mode', true)), FILTER_VALIDATE_BOOLEAN);

        // If Yalidine API credentials are not configured yet, safely operate in stub/fallback mode
        $this->stubMode = $configuredStub || empty($this->apiId) || empty($this->apiToken);
    }

    public function isStubMode(): bool
    {
        return $this->stubMode;
    }

    /**
     * Normalize delivery type to dzship values: "stopdesk" or "home".
     */
    public function normalizeDeliveryType(?string $deliveryType, $isStopDesk = null): string
    {
        if (!empty($deliveryType)) {
            $clean = strtolower(trim($deliveryType));
            if (in_array($clean, ['stopdesk', 'stop_desk', 'stop-desk', 'desk', 'bureau'], true)) {
                return 'stopdesk';
            }
            if (in_array($clean, ['home', 'domicile', 'home_delivery'], true)) {
                return 'home';
            }
        }

        if ($isStopDesk !== null && filter_var($isStopDesk, FILTER_VALIDATE_BOOLEAN)) {
            return 'stopdesk';
        }

        return 'home';
    }

    /**
     * Fetch all 58 Algerian Wilayas from dzship (cached 7 days) with local JSON/config fallback.
     *
     * @return array<int, array{code:int, name_fr:string, name_ar:string}>
     */
    public function getWilayas(): array
    {
        return Cache::remember('dzship:yalidine:wilayas:v1', self::CACHE_TTL_SECONDS, function () {
            try {
                $response = Http::timeout(10)
                    ->acceptJson()
                    ->get("{$this->baseUrl}/v1/wilayas");

                if ($response->successful()) {
                    $rows = $response->json();
                    if (is_array($rows) && count($rows) >= 48) {
                        $normalized = [];
                        foreach ($rows as $row) {
                            if (!is_array($row)) {
                                continue;
                            }
                            $code = (int) ($row['code'] ?? 0);
                            if ($code < 1 || $code > 58) {
                                continue;
                            }
                            $normalized[$code] = [
                                'code' => $code,
                                'name_fr' => (string) ($row['nameFr'] ?? $row['name_fr'] ?? $this->getWilayaNameFr($code)),
                                'name_ar' => (string) ($row['nameAr'] ?? $row['name_ar'] ?? $this->getWilayaNameAr($code)),
                            ];
                        }

                        if (!empty($normalized)) {
                            ksort($normalized);
                            return array_values($normalized);
                        }
                    }
                }
            } catch (\Throwable $e) {
                Log::warning('DzshipYalidineService::getWilayas failed, using local fallback: ' . $e->getMessage());
            }

            return $this->getFallbackWilayas();
        });
    }

    /**
     * Fetch Communes / Regions for a specific Wilaya from dzship (cached 7 days) with fallback.
     *
     * @return array<int, array{id:int, name_fr:string, name_ar:string, wilaya_code:int}>
     */
    public function getCommunes(int $wilayaCode): array
    {
        $wilayaCode = $this->normalizeWilayaCode($wilayaCode);

        return Cache::remember("dzship:yalidine:communes:{$wilayaCode}:v1", self::CACHE_TTL_SECONDS, function () use ($wilayaCode) {
            try {
                $response = Http::timeout(10)
                    ->acceptJson()
                    ->get("{$this->baseUrl}/v1/communes", [
                        'wilaya' => $wilayaCode,
                    ]);

                if ($response->successful()) {
                    $rows = $response->json();
                    if (is_array($rows) && !empty($rows)) {
                        $normalized = [];
                        $index = 1;
                        foreach ($rows as $row) {
                            if (!is_array($row)) {
                                continue;
                            }
                            $nameFr = trim((string) ($row['nameFr'] ?? $row['name_fr'] ?? $row['name'] ?? ''));
                            $nameAr = trim((string) ($row['nameAr'] ?? $row['name_ar'] ?? ''));
                            if ($nameFr === '') {
                                continue;
                            }
                            $normalized[] = [
                                'id' => isset($row['id']) && is_numeric($row['id'])
                                    ? (int) $row['id']
                                    : ($wilayaCode * 1000 + $index),
                                'name_fr' => $nameFr,
                                'name_ar' => $nameAr,
                                'wilaya_code' => (int) ($row['wilayaCode'] ?? $row['wilaya_code'] ?? $wilayaCode),
                            ];
                            $index++;
                        }

                        if (!empty($normalized)) {
                            usort($normalized, fn ($a, $b) => strcmp($a['name_fr'], $b['name_fr']));
                            return $normalized;
                        }
                    }
                }
            } catch (\Throwable $e) {
                Log::warning("DzshipYalidineService::getCommunes({$wilayaCode}) failed, using fallback: " . $e->getMessage());
            }

            return $this->getFallbackCommunes($wilayaCode);
        });
    }

    /**
     * Fetch Yalidine Stop-Desk branches for a destination Wilaya.
     *
     * @return array<int, array{id:string, name:string, communeName:string, address:string, wilaya_code:int}>
     */
    public function getDesks(int $wilayaCode): array
    {
        $wilayaCode = $this->normalizeWilayaCode($wilayaCode);
        $cacheKey = 'dzship:yalidine:desks:' . ($this->stubMode ? 'stub:' : 'live:') . $wilayaCode . ':v1';

        return Cache::remember($cacheKey, 86400, function () use ($wilayaCode) {
            if (!$this->stubMode) {
                try {
                    $response = Http::timeout(10)
                        ->acceptJson()
                        ->post("{$this->baseUrl}/v1/desks", [
                            'courier' => self::COURIER_YALIDINE,
                            'credentials' => [
                                'apiId' => $this->apiId,
                                'apiToken' => $this->apiToken,
                            ],
                            'wilayaCode' => $wilayaCode,
                        ]);

                    if ($response->successful()) {
                        $rows = $response->json();
                        if (isset($rows['data']) && is_array($rows['data'])) {
                            $rows = $rows['data'];
                        }
                        if (is_array($rows) && !empty($rows)) {
                            $desks = [];
                            foreach ($rows as $row) {
                                if (!is_array($row)) {
                                    continue;
                                }
                                $id = (string) ($row['id'] ?? $row['stopDeskId'] ?? $row['center_id'] ?? '');
                                $name = trim((string) ($row['name'] ?? ''));
                                $communeName = trim((string) ($row['communeName'] ?? $row['commune_name'] ?? $this->getWilayaNameFr($wilayaCode)));
                                if ($id === '' || $name === '') {
                                    continue;
                                }
                                $desks[] = [
                                    'id' => $id,
                                    'name' => $name,
                                    'communeName' => $communeName,
                                    'address' => (string) ($row['address'] ?? ($communeName . ', ' . $this->getWilayaNameFr($wilayaCode))),
                                    'wilaya_code' => $wilayaCode,
                                ];
                            }
                            if (!empty($desks)) {
                                return $desks;
                            }
                        }
                    }
                } catch (\Throwable $e) {
                    Log::warning("DzshipYalidineService::getDesks({$wilayaCode}) live call failed, using fallback: " . $e->getMessage());
                }
            }

            return $this->getFallbackDesks($wilayaCode);
        });
    }

    /**
     * Resolve origin Wilaya code (1..58) from an item's location, vendor address, or explicit input.
     */
    public function resolveItemFromWilaya(?int $itemId = null, ?int $vendorId = null, $explicitFromWilaya = null): int
    {
        if ($explicitFromWilaya !== null && $explicitFromWilaya !== '') {
            $parsed = $this->tryParseWilayaCode($explicitFromWilaya);
            if ($parsed !== null) {
                return $parsed;
            }
        }

        if (!empty($itemId)) {
            $item = DB::table('psx_items')
                ->select('id', 'location_city_id', 'vendor_id')
                ->where('id', $itemId)
                ->first();

            if ($item) {
                if (!empty($item->location_city_id)) {
                    // Prefer matching psx_location_cities.name against Algerian wilaya names
                    $city = DB::table('psx_location_cities')
                        ->select('id', 'name')
                        ->where('id', $item->location_city_id)
                        ->first();

                    if ($city && !empty($city->name)) {
                        $byName = $this->tryParseWilayaCode($city->name);
                        if ($byName !== null) {
                            return $byName;
                        }
                    }

                    $byId = $this->tryParseWilayaCode($item->location_city_id);
                    if ($byId !== null) {
                        return $byId;
                    }
                }

                if (empty($vendorId) && !empty($item->vendor_id)) {
                    $vendorId = (int) $item->vendor_id;
                }
            }
        }

        if (!empty($vendorId)) {
            $vendor = DB::table('psx_vendors')
                ->select('id', 'address', 'name')
                ->where('id', $vendorId)
                ->first();

            if ($vendor && !empty($vendor->address)) {
                $byVendor = $this->tryParseWilayaCode($vendor->address);
                if ($byVendor !== null) {
                    return $byVendor;
                }
            }
        }

        return 16; // Default origin: Alger
    }

    /**
     * Calculate Yalidine Stop-Desk & Home Delivery quotes in DZD for an item and destination.
     */
    public function getYalidineQuote(
        ?int $itemId,
        $toWilayaInput,
        ?string $toCommuneName = null,
        $fromWilayaOverride = null,
        ?int $vendorId = null
    ): array {
        $fromWilayaCode = $this->resolveItemFromWilaya($itemId, $vendorId, $fromWilayaOverride);
        $toWilayaCode = $this->normalizeWilayaCode($toWilayaInput);
        $cleanCommune = $toCommuneName ? trim($toCommuneName) : null;

        $fallbackQuote = $this->computeFallbackQuote($fromWilayaCode, $toWilayaCode);
        $stopDeskPrice = $fallbackQuote['stop_desk_dzd'];
        $homePrice = $fallbackQuote['home_dzd'];
        $estimatedDays = $fallbackQuote['estimated_days'];
        $usedStub = $this->stubMode;

        if (!$this->stubMode) {
            $liveDesk = $this->fetchLiveRate($fromWilayaCode, $toWilayaCode, 'stopdesk', $cleanCommune);
            $liveHome = $this->fetchLiveRate($fromWilayaCode, $toWilayaCode, 'home', $cleanCommune);

            if ($liveDesk !== null) {
                $stopDeskPrice = (int) round($liveDesk['delivery_fee']);
                if (!empty($liveDesk['estimated_days'])) {
                    $estimatedDays = (int) $liveDesk['estimated_days'];
                }
            }
            if ($liveHome !== null) {
                $homePrice = (int) round($liveHome['delivery_fee']);
            }
            if ($liveDesk === null && $liveHome === null) {
                $usedStub = true;
            }
        }

        $desks = $this->getDesks($toWilayaCode);
        $fromWilayaName = $this->getWilayaNameFr($fromWilayaCode);
        $toWilayaName = $this->getWilayaNameFr($toWilayaCode);

        return [
            'status' => 'success',
            'courier' => self::COURIER_YALIDINE,
            'is_stub' => $usedStub,
            'currency' => 'DZD',
            'currency_symbol' => 'DA',
            'from_wilaya_code' => $fromWilayaCode,
            'from_wilaya_name' => $fromWilayaName,
            'to_wilaya_code' => $toWilayaCode,
            'to_wilaya_name' => $toWilayaName,
            'to_wilaya_name_ar' => $this->getWilayaNameAr($toWilayaCode),
            'to_commune_name' => $cleanCommune ?: $toWilayaName,
            'stop_desk' => [
                'delivery_type' => 'stopdesk',
                'label' => 'Yalidine Stop-Desk (Bureau Yalidine)',
                'price_dzd' => $stopDeskPrice,
                'estimated_days' => $estimatedDays,
                'desks' => $desks,
            ],
            'home_delivery' => [
                'delivery_type' => 'home',
                'label' => 'Yalidine Livraison à Domicile',
                'price_dzd' => $homePrice,
                'estimated_days' => $estimatedDays,
            ],
            'desk_fee' => $stopDeskPrice,
            'home_fee' => $homePrice,
        ];
    }

    /**
     * Create a Yalidine parcel via DZBuild dzship (POST /v1/orders).
     * Uses courier "sandbox" when YALIDINE_STUB_MODE=true and "yalidine" once credentials are configured.
     */
    public function createShipment(Order $order): array
    {
        $order->loadMissing(['shippingAndBilling', 'orderItems.item', 'user']);
        $shipping = $order->shippingAndBilling;

        $firstItemId = $order->orderItems->first()?->item_id;
        $fromWilaya = $this->resolveItemFromWilaya(
            $firstItemId ? (int) $firstItemId : null,
            $order->vendor_id ? (int) $order->vendor_id : null,
            $order->from_wilaya_id
        );

        $toWilayaCode = $this->normalizeWilayaCode(
            $order->to_wilaya_id ?: ($shipping?->shipping_state ?: ($shipping?->shipping_city ?: 16))
        );
        $toWilayaName = $this->getWilayaNameFr($toWilayaCode);

        $deliveryType = $this->normalizeDeliveryType($order->delivery_type);
        $isStopDesk = ($deliveryType === 'stopdesk');

        $stopDeskId = $order->yalidine_stop_desk_id ? (string) $order->yalidine_stop_desk_id : null;
        $toCommuneName = trim((string) ($order->to_commune_name ?: ($shipping?->shipping_city ?: $toWilayaName)));
        $stopDeskName = null;

        // For Stop-Desk orders, match the selected desk to ensure communeName matches the desk's communeName
        if ($isStopDesk) {
            $desks = $this->getDesks($toWilayaCode);
            $matchedDesk = null;
            if (!empty($stopDeskId)) {
                foreach ($desks as $desk) {
                    if ((string) $desk['id'] === $stopDeskId) {
                        $matchedDesk = $desk;
                        break;
                    }
                }
            }
            if ($matchedDesk === null && !empty($desks)) {
                $matchedDesk = $desks[0];
                $stopDeskId = (string) $matchedDesk['id'];
            }
            if ($matchedDesk !== null) {
                $toCommuneName = (string) ($matchedDesk['communeName'] ?: $toCommuneName);
                $stopDeskName = (string) ($matchedDesk['name'] ?? null);
            }
        }

        $fullName = trim((string) (($shipping?->shipping_first_name ?? '') . ' ' . ($shipping?->shipping_last_name ?? '')));
        if ($fullName === '' || $fullName === '-') {
            $fullName = trim((string) ($order->user?->name ?? 'Client Dressy'));
        }
        $phone = $this->normalizeAlgerianPhone((string) ($shipping?->shipping_phone_no ?? $order->user?->user_phone ?? '0550000000'));

        $productNames = [];
        foreach ($order->orderItems as $oi) {
            $title = $oi->item?->title ?? ('Article #' . $oi->item_id);
            $qty = max(1, (int) ($oi->quantity ?? 1));
            $productNames[] = "{$title} x{$qty}";
        }
        $productList = Str::limit(implode(', ', $productNames) ?: "Commande Dressy #{$order->order_code}", 480, '');

        $addressLine = $isStopDesk && $stopDeskName
            ? "{$stopDeskName}, {$toWilayaName}"
            : "{$toCommuneName}, {$toWilayaName}";

        $orderRef = (string) ($order->order_code ?: ('DRS-' . $order->id));
        $codAmount = max(0, (int) round((float) $order->total_price));

        $payload = [
            'courier' => $this->stubMode ? self::COURIER_SANDBOX : self::COURIER_YALIDINE,
            'options' => [
                'fromWilaya' => $fromWilaya,
            ],
            'order' => [
                'reference' => $orderRef,
                'recipient' => [
                    'fullName' => $fullName,
                    'phone' => $phone,
                    'wilayaCode' => $toWilayaCode,
                    'communeName' => $toCommuneName,
                    'addressLine' => $addressLine,
                ],
                'deliveryType' => $deliveryType,
                'productList' => $productList,
                'codAmount' => $codAmount,
                'freeShipping' => false,
            ],
        ];

        if ($isStopDesk && !empty($stopDeskId)) {
            $payload['order']['stopDeskId'] = $stopDeskId;
        }

        if (!$this->stubMode) {
            $payload['credentials'] = [
                'apiId' => $this->apiId,
                'apiToken' => $this->apiToken,
            ];
        }

        try {
            $response = Http::timeout(15)
                ->acceptJson()
                ->post("{$this->baseUrl}/v1/orders", $payload);

            $body = $response->json();

            if ($response->successful() && is_array($body) && !empty($body['trackingNumber'])) {
                $tracking = (string) $body['trackingNumber'];
                $parcelId = (string) ($body['courierReference'] ?? $body['reference'] ?? $tracking);
                $labelUrl = (string) ($body['labelUrl'] ?? "https://api.yalidine.app/v1/parcels/print/?tracking={$tracking}");
                $status = (string) ($body['status'] ?? 'dispatched');

                $this->persistShipmentOnOrder($order, $tracking, $parcelId, $labelUrl, $status);

                return [
                    'success' => true,
                    'tracking' => $tracking,
                    'parcel_id' => $parcelId,
                    'label_url' => $labelUrl,
                    'status' => $status,
                    'courier' => $payload['courier'],
                    'is_stub' => $this->stubMode,
                ];
            }

            $errorMessage = is_array($body)
                ? ($body['error']['message'] ?? $body['message'] ?? "dzship HTTP {$response->status()}")
                : "dzship HTTP {$response->status()}";

            Log::warning("DzshipYalidineService::createShipment failed for Order #{$order->id}: {$errorMessage}", [
                'courier' => $payload['courier'],
                'status' => $response->status(),
                'body' => $body,
            ]);

            if (!$this->stubMode) {
                return [
                    'success' => false,
                    'error' => $errorMessage,
                ];
            }
        } catch (\Throwable $e) {
            Log::warning("DzshipYalidineService::createShipment exception for Order #{$order->id}: " . $e->getMessage());
            if (!$this->stubMode) {
                return [
                    'success' => false,
                    'error' => 'Connection to Yalidine shipping service failed: ' . $e->getMessage(),
                ];
            }
        }

        // Graceful stub fallback when YALIDINE_STUB_MODE=true and sandbox upstream is unavailable
        $stubTracking = 'YAL-SBX-' . $orderRef . '-' . strtoupper(Str::random(4));
        $stubParcelId = 'SBX-' . strtoupper(Str::random(6));
        $stubLabelUrl = "https://api.yalidine.app/v1/parcels/print/?tracking={$stubTracking}";

        $this->persistShipmentOnOrder($order, $stubTracking, $stubParcelId, $stubLabelUrl, 'dispatched');

        return [
            'success' => true,
            'tracking' => $stubTracking,
            'parcel_id' => $stubParcelId,
            'label_url' => $stubLabelUrl,
            'status' => 'dispatched',
            'courier' => self::COURIER_SANDBOX,
            'is_stub' => true,
        ];
    }

    /**
     * Normalize any wilaya code or name string to a valid Algerian wilaya code (1..58).
     */
    public function normalizeWilayaCode($value): int
    {
        return $this->tryParseWilayaCode($value) ?? 16;
    }

    public function tryParseWilayaCode($value): ?int
    {
        if ($value === null || $value === '') {
            return null;
        }

        if (is_numeric($value)) {
            $intVal = (int) $value;
            if ($intVal >= 1 && $intVal <= 58) {
                return $intVal;
            }
        }

        $str = trim((string) $value);
        if (preg_match('/^\s*(\d{1,2})\b/', $str, $matches)) {
            $intVal = (int) $matches[1];
            if ($intVal >= 1 && $intVal <= 58) {
                return $intVal;
            }
        }

        $needle = $this->normalizeForMatch($str);
        if ($needle === '') {
            return null;
        }

        // Common English aliases
        if (str_contains($needle, 'algiers')) {
            return 16;
        }

        $wilayas = config('yalidine_rates.wilayas', []);
        foreach ($wilayas as $code => $meta) {
            $fr = $this->normalizeForMatch((string) ($meta['name_fr'] ?? ''));
            $ar = trim((string) ($meta['name_ar'] ?? ''));
            if ($fr !== '' && ($needle === $fr || str_contains($needle, $fr) || str_contains($fr, $needle))) {
                return (int) $code;
            }
            if ($ar !== '' && str_contains($str, $ar)) {
                return (int) $code;
            }
        }

        return null;
    }

    public function getWilayaNameFr(int $code): string
    {
        $wilayas = config('yalidine_rates.wilayas', []);
        return (string) ($wilayas[$code]['name_fr'] ?? 'Alger');
    }

    public function getWilayaNameAr(int $code): string
    {
        $wilayas = config('yalidine_rates.wilayas', []);
        return (string) ($wilayas[$code]['name_ar'] ?? 'الجزائر');
    }

    /**
     * Query dzship POST /v1/rates for live Yalidine pricing.
     *
     * @return array{delivery_fee:float, estimated_days:?int}|null
     */
    protected function fetchLiveRate(int $fromWilaya, int $toWilaya, string $deliveryType, ?string $toCommune = null): ?array
    {
        $query = [
            'fromWilaya' => $fromWilaya,
            'toWilaya' => $toWilaya,
            'deliveryType' => $deliveryType,
        ];
        if (!empty($toCommune)) {
            $query['toCommune'] = $toCommune;
        }

        $cacheKey = 'dzship:yalidine:rate:' . md5(json_encode($query));

        return Cache::remember($cacheKey, 21600, function () use ($fromWilaya, $query) {
            try {
                $response = Http::timeout(10)
                    ->acceptJson()
                    ->post("{$this->baseUrl}/v1/rates", [
                        'courier' => self::COURIER_YALIDINE,
                        'credentials' => [
                            'apiId' => $this->apiId,
                            'apiToken' => $this->apiToken,
                        ],
                        'options' => [
                            'fromWilaya' => $fromWilaya,
                        ],
                        'query' => $query,
                    ]);

                if ($response->successful()) {
                    $data = $response->json();
                    if (is_array($data) && isset($data['deliveryFee']) && is_numeric($data['deliveryFee'])) {
                        return [
                            'delivery_fee' => (float) $data['deliveryFee'],
                            'estimated_days' => isset($data['estimatedDays']) ? (int) $data['estimatedDays'] : null,
                        ];
                    }
                }
            } catch (\Throwable $e) {
                Log::warning('DzshipYalidineService::fetchLiveRate error: ' . $e->getMessage());
            }

            return null;
        });
    }

    /**
     * Compute realistic fallback Yalidine DZD fees from config/yalidine_rates.php.
     *
     * @return array{home_dzd:int, stop_desk_dzd:int, estimated_days:int}
     */
    protected function computeFallbackQuote(int $fromWilaya, int $toWilaya): array
    {
        $wilayas = config('yalidine_rates.wilayas', []);
        $fromMeta = $wilayas[$fromWilaya] ?? ['zone' => 'north_center', 'home_dzd' => 600, 'stop_desk_dzd' => 400, 'days' => 2];
        $toMeta = $wilayas[$toWilaya] ?? ['zone' => 'north_center', 'home_dzd' => 600, 'stop_desk_dzd' => 400, 'days' => 2];

        // Same wilaya local rate
        if ($fromWilaya === $toWilaya) {
            $isDeepSouth = in_array($toMeta['zone'] ?? '', ['south', 'deep_south'], true);
            return [
                'home_dzd' => $isDeepSouth ? 500 : 400,
                'stop_desk_dzd' => $isDeepSouth ? 350 : 300,
                'estimated_days' => 1,
            ];
        }

        // Standard tariff table (origin Alger or adjusted by zone proximity)
        $home = (int) ($toMeta['home_dzd'] ?? 650);
        $desk = (int) ($toMeta['stop_desk_dzd'] ?? 400);
        $days = (int) ($toMeta['days'] ?? 2);

        // If origin is outside Algiers and in the same zone as destination, apply minor regional discount
        if ($fromWilaya !== 16 && ($fromMeta['zone'] ?? '') === ($toMeta['zone'] ?? '')) {
            $home = max(450, $home - 100);
            $desk = max(300, $desk - 50);
            $days = max(1, $days - 1);
        }

        return [
            'home_dzd' => $home,
            'stop_desk_dzd' => $desk,
            'estimated_days' => $days,
        ];
    }

    protected function getFallbackWilayas(): array
    {
        $wilayas = config('yalidine_rates.wilayas', []);
        $list = [];
        foreach ($wilayas as $code => $meta) {
            $list[] = [
                'code' => (int) $code,
                'name_fr' => (string) ($meta['name_fr'] ?? "Wilaya {$code}"),
                'name_ar' => (string) ($meta['name_ar'] ?? ''),
            ];
        }
        usort($list, fn ($a, $b) => $a['code'] <=> $b['code']);
        return $list;
    }

    protected function getFallbackCommunes(int $wilayaCode): array
    {
        $nameFr = $this->getWilayaNameFr($wilayaCode);
        $nameAr = $this->getWilayaNameAr($wilayaCode);

        return [
            [
                'id' => $wilayaCode * 1000 + 1,
                'name_fr' => $nameFr,
                'name_ar' => $nameAr,
                'wilaya_code' => $wilayaCode,
            ],
        ];
    }

    protected function getFallbackDesks(int $wilayaCode): array
    {
        $configured = config("yalidine_rates.desks.{$wilayaCode}");
        $wilayaName = $this->getWilayaNameFr($wilayaCode);

        if (is_array($configured) && !empty($configured)) {
            return array_map(function ($desk) use ($wilayaCode, $wilayaName) {
                return [
                    'id' => (string) $desk['id'],
                    'name' => (string) $desk['name'],
                    'communeName' => (string) ($desk['communeName'] ?? $wilayaName),
                    'address' => (string) ($desk['address'] ?? $wilayaName),
                    'wilaya_code' => $wilayaCode,
                ];
            }, $configured);
        }

        // Deterministic numeric Stop-Desk ID for every Algerian wilaya
        return [
            [
                'id' => (string) ($wilayaCode * 10000 + 101),
                'name' => "Agence Yalidine {$wilayaName} Centre",
                'communeName' => $wilayaName,
                'address' => "Centre-ville, {$wilayaName}",
                'wilaya_code' => $wilayaCode,
            ],
        ];
    }

    protected function persistShipmentOnOrder(
        Order $order,
        string $tracking,
        string $parcelId,
        string $labelUrl,
        string $status
    ): void {
        $order->yalidine_tracking = $tracking;
        $order->yalidine_parcel_id = $parcelId;
        $order->yalidine_label_url = $labelUrl;
        $order->yalidine_parcel_status = $status;
        $order->yalidine_status = $status;
        $order->save();
    }

    protected function normalizeAlgerianPhone(string $phone): string
    {
        $digits = preg_replace('/\D+/', '', $phone) ?? '';
        if (str_starts_with($digits, '213') && strlen($digits) >= 12) {
            $digits = '0' . substr($digits, 3);
        } elseif (str_starts_with($digits, '00213') && strlen($digits) >= 14) {
            $digits = '0' . substr($digits, 5);
        } elseif (strlen($digits) === 9 && in_array($digits[0], ['5', '6', '7'], true)) {
            $digits = '0' . $digits;
        }

        if (strlen($digits) !== 10 || !in_array(substr($digits, 0, 2), ['05', '06', '07'], true)) {
            return $digits !== '' ? $digits : '0550000000';
        }

        return $digits;
    }

    protected function normalizeForMatch(string $text): string
    {
        $ascii = Str::ascii(strtolower(trim($text)));
        return preg_replace('/[^a-z0-9]+/', ' ', $ascii) ?? '';
    }
}
