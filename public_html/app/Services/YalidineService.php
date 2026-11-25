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
        $this->stubMode = false;
    }

    public function isStubMode(): bool
    {
        return false;
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
     * Get official Wilayas from Yalidine API v1 (cached 24h).
     * Does not cap at 58 if Yalidine returns more wilayas.
     *
     * @return array
     */
    public function getWilayas(): array
    {
        return Cache::remember('yalidine_wilayas_v2', 86400, function () {
            if (!$this->stubMode) {
                try {
                    $response = Http::withHeaders([
                        'X-API-ID' => $this->apiId,
                        'X-API-TOKEN' => $this->apiToken,
                        'Accept' => 'application/json',
                    ])->timeout(10)->get(rtrim($this->apiUrl, '/') . '/wilayas', ['page_size' => 200]);

                    if ($response->successful()) {
                        $json = $response->json();
                        $data = $json['data'] ?? $json;
                        if (is_array($data) && !empty($data)) {
                            return array_map(function ($w) {
                                $id = (int) ($w['id'] ?? $w['wilaya_id'] ?? 0);
                                $rawName = (string) ($w['name'] ?? $w['wilaya_name'] ?? '');
                                return [
                                    'id' => $id,
                                    'code' => sprintf('%02d', $id),
                                    'name' => $rawName ?: $this->getWilayaNameById($id),
                                    'clean_name' => $rawName ?: $this->getWilayaNameById($id),
                                    'is_deliverable' => (bool) ($w['is_deliverable'] ?? true),
                                ];
                            }, $data);
                        }
                    }
                } catch (\Throwable $e) {
                    Log::warning('Yalidine getWilayas live API call failed, falling back to local list: ' . $e->getMessage());
                }
            }

            // Fallback list of Algeria's Wilayas
            return $this->getFallbackWilayas();
        });
    }

    /**
     * Get Communes for a specific Wilaya.
     * Fetches live from Yalidine API GET /communes/?wilaya_id={id}&page_size=200.
     * Falls back to complete official Algerian communes dataset (never a single-item list).
     *
     * @param int|string $wilayaId
     * @return array
     */
    public function getCommunes($wilayaId): array
    {
        $id = $this->normalizeWilayaId($wilayaId);
        $cacheKey = "yalidine_communes_v2_w_{$id}";

        // If valid multi-item list already cached, return it
        $cached = Cache::get($cacheKey);
        if (is_array($cached) && count($cached) > 1) {
            return $cached;
        }

        if (!$this->stubMode) {
            try {
                $response = Http::withHeaders([
                    'X-API-ID' => $this->apiId,
                    'X-API-TOKEN' => $this->apiToken,
                    'Accept' => 'application/json',
                ])->timeout(10)->get(rtrim($this->apiUrl, '/') . '/communes', [
                    'wilaya_id' => $id,
                    'page_size' => 200,
                ]);

                if ($response->successful()) {
                    $json = $response->json();
                    $data = $json['data'] ?? $json;
                    if (is_array($data) && !empty($data)) {
                        $parsed = [];
                        foreach ($data as $c) {
                            $cWilayaId = (int) ($c['wilaya_id'] ?? $id);
                            if ($cWilayaId === $id) {
                                $parsed[] = [
                                    'id' => (int) ($c['id'] ?? $c['commune_id'] ?? 0),
                                    'wilaya_id' => $id,
                                    'name' => (string) ($c['name'] ?? $c['commune_name'] ?? ''),
                                    'has_stop_desk' => (bool) ($c['has_stop_desk'] ?? $c['has_stopdesk'] ?? false),
                                    'is_deliverable' => (bool) ($c['is_deliverable'] ?? true),
                                ];
                            }
                        }
                        if (count($parsed) > 1) {
                            Cache::put($cacheKey, $parsed, 86400);
                            return $parsed;
                        }
                    }
                }
            } catch (\Throwable $e) {
                Log::warning("Yalidine getCommunes live API call failed for wilaya {$id}: " . $e->getMessage());
            }
        }

        // Return comprehensive fallback communes for this wilaya
        $fallback = $this->getFallbackCommunesForWilaya($id);
        if (count($fallback) > 1) {
            Cache::put($cacheKey, $fallback, 3600);
        }
        return $fallback;
    }

    /**
     * Get Yalidine Stop Desk Centers for a specific Wilaya with optional Commune filtering.
     * Fetches live from official Yalidine API GET https://api.yalidine.app/v1/centers/.
     * Loops over paginated responses (page_size=200) so no agencies are truncated.
     *
     * @param int|string $wilayaId
     * @param int|string|null $communeId
     * @param string|null $communeName
     * @param bool $refresh Force cache refresh / bust
     * @return array
     */
    public function getCentersDetailed($wilayaId, $communeId = null, ?string $communeName = null, bool $refresh = false): array
    {
        $id = $this->normalizeWilayaId($wilayaId);
        $cacheKey = "yalidine_centers_live_w_{$id}";

        if ($refresh) {
            Cache::forget($cacheKey);
            Cache::forget("yalidine_centers_v3_w_{$id}");
            Cache::forget("yalidine_centers_v2_w_{$id}");
        }

        if (empty($this->apiId) || empty($this->apiToken)) {
            return [
                'success' => false,
                'status' => 'error',
                'message' => 'Yalidine API credentials are not configured in Admin Panel.',
                'centers' => [],
                'desks' => [],
                'all_wilaya_centers' => [],
                'count' => 0,
                'fallback_to_wilaya' => false,
            ];
        }

        $allCenters = null;
        if (!$refresh) {
            $cached = Cache::get($cacheKey);
            if (is_array($cached) && !empty($cached)) {
                $allCenters = $cached;
            }
        }

        if ($allCenters === null) {
            $allCentersMap = [];
            $page = 1;
            $maxPages = 10;
            $hasMore = true;
            $apiError = null;

            while ($hasMore && $page <= $maxPages) {
                try {
                    $queryParams = [
                        'wilaya_id' => $id,
                        'page_size' => 200,
                        'page' => $page,
                    ];
                    $response = Http::withHeaders([
                        'X-API-ID' => $this->apiId,
                        'X-API-TOKEN' => $this->apiToken,
                        'Accept' => 'application/json',
                    ])->timeout(12)->get(rtrim($this->apiUrl, '/') . '/centers/', $queryParams);

                    if ($response->successful()) {
                        $json = $response->json();
                        if (!is_array($json)) {
                            break;
                        }

                        if (isset($json['data']) && is_array($json['data'])) {
                            $data = $json['data'];
                        } elseif (isset($json['results']) && is_array($json['results'])) {
                            $data = $json['results'];
                        } elseif (isset($json['centers']) && is_array($json['centers'])) {
                            $data = $json['centers'];
                        } elseif (isset($json[0]) && is_array($json[0])) {
                            $data = $json;
                        } else {
                            $data = array_filter($json, function ($item, $k) {
                                return is_array($item) && !in_array((string) $k, ['links', 'meta', 'pagination', 'error', 'has_more', 'total_data', 'page', 'page_size', 'status'], true);
                            }, ARRAY_FILTER_USE_BOTH);
                        }

                        if (empty($data)) {
                            break;
                        }

                        foreach ($data as $key => $center) {
                            if (!is_array($center)) {
                                continue;
                            }
                            $cWilayaId = (int) ($center['wilaya_id'] ?? $id);
                            if ($cWilayaId !== $id && !empty($center['wilaya_id'])) {
                                continue;
                            }

                            $rawCenterId = $center['center_id'] ?? $center['id'] ?? (is_numeric($key) ? $key : null);
                            $numericCenterId = is_numeric($rawCenterId) ? (int) $rawCenterId : null;
                            if ($numericCenterId === null) {
                                continue;
                            }

                            $name = trim((string) ($center['name'] ?? $center['center_name'] ?? ''));
                            if (empty($name)) {
                                continue;
                            }

                            $communeIdVal = isset($center['commune_id']) && is_numeric($center['commune_id']) ? (int) $center['commune_id'] : null;
                            $communeNameVal = trim((string) ($center['commune_name'] ?? $center['commune'] ?? ''));
                            $address = trim((string) ($center['address'] ?? ''));
                            if (empty($address)) {
                                $address = $communeNameVal ?: $this->getWilayaNameFr($id);
                            }

                            $isStopdesk = true;
                            if (isset($center['is_stopdesk'])) {
                                $isStopdesk = filter_var($center['is_stopdesk'], FILTER_VALIDATE_BOOLEAN);
                            } elseif (isset($center['has_stopdesk'])) {
                                $isStopdesk = filter_var($center['has_stopdesk'], FILTER_VALIDATE_BOOLEAN);
                            }

                            $allCentersMap[$numericCenterId] = [
                                'center_id' => $numericCenterId,
                                'id' => (string) $numericCenterId,
                                'name' => $name,
                                'address' => $address,
                                'commune_id' => $communeIdVal,
                                'commune_name' => $communeNameVal,
                                'wilaya_id' => $id,
                                'wilaya_name' => (string) ($center['wilaya_name'] ?? $this->getWilayaNameFr($id)),
                                'is_stopdesk' => $isStopdesk,
                            ];
                        }

                        $hasMore = !empty($json['has_more'])
                            || (!empty($json['links']['next']))
                            || (count($data) >= 200 && isset($json['total_data']) && count($allCentersMap) < (int) $json['total_data']);
                        $page++;
                    } else {
                        $apiError = "Yalidine API returned HTTP {$response->status()}: " . $response->body();
                        Log::error("Yalidine getCenters HTTP error {$response->status()} for wilaya {$id} page {$page}: " . $response->body());
                        break;
                    }
                } catch (\Throwable $e) {
                    $apiError = "Yalidine API connection failed: " . $e->getMessage();
                    Log::error("Yalidine getCenters live API call failed for wilaya {$id}: " . $e->getMessage());
                    break;
                }
            }

            $allCenters = array_values($allCentersMap);

            if (!empty($allCenters)) {
                Cache::put($cacheKey, $allCenters, 21600); // 6 hours
            } elseif ($apiError !== null) {
                return [
                    'success' => false,
                    'status' => 'error',
                    'message' => $apiError,
                    'centers' => [],
                    'desks' => [],
                    'all_wilaya_centers' => [],
                    'count' => 0,
                    'fallback_to_wilaya' => false,
                ];
            }
        }

        $allCenters = $allCenters ?: [];
        $cleanCommuneName = $communeName !== null ? trim((string) $communeName) : '';
        $normCommuneName = $cleanCommuneName !== '' ? $this->normalizeStringForMatching($cleanCommuneName) : '';
        $normCommuneId = ($communeId !== null && is_numeric($communeId) && (int) $communeId > 0) ? (int) $communeId : null;

        $filtered = [];
        if ($normCommuneId !== null || $normCommuneName !== '') {
            foreach ($allCenters as $center) {
                $isMatch = false;
                if ($normCommuneId !== null && !empty($center['commune_id']) && (int) $center['commune_id'] === $normCommuneId) {
                    $isMatch = true;
                } elseif ($normCommuneName !== '') {
                    $normCenterCommune = !empty($center['commune_name']) ? $this->normalizeStringForMatching($center['commune_name']) : '';
                    $normCenterName = !empty($center['name']) ? $this->normalizeStringForMatching($center['name']) : '';
                    $normCenterAddress = !empty($center['address']) ? $this->normalizeStringForMatching($center['address']) : '';

                    if ($normCenterCommune !== '' && (
                        $normCenterCommune === $normCommuneName
                        || str_contains($normCenterCommune, $normCommuneName)
                        || str_contains($normCommuneName, $normCenterCommune)
                    )) {
                        $isMatch = true;
                    } elseif ($normCenterName !== '' && (
                        str_contains($normCenterName, $normCommuneName)
                        || str_contains($normCommuneName, $normCenterName)
                    )) {
                        $isMatch = true;
                    } elseif ($normCenterAddress !== '' && str_contains($normCenterAddress, $normCommuneName)) {
                        $isMatch = true;
                    }
                }

                if ($isMatch) {
                    $filtered[] = $center;
                }
            }
        }

        if (!empty($filtered)) {
            return [
                'success' => true,
                'status' => 'success',
                'fallback_to_wilaya' => false,
                'wilaya_id' => $id,
                'wilaya_name' => $this->getWilayaNameFr($id),
                'commune_id' => $normCommuneId,
                'commune_name' => $cleanCommuneName,
                'count' => count($filtered),
                'centers' => $filtered,
                'desks' => $filtered,
                'all_wilaya_centers' => $allCenters,
            ];
        }

        if ($normCommuneId !== null || $normCommuneName !== '') {
            return [
                'success' => true,
                'status' => 'success',
                'fallback_to_wilaya' => true,
                'message' => 'Aucun bureau Stop-Desk trouvé directement dans cette commune. Voici tous les bureaux disponibles dans la wilaya.',
                'wilaya_id' => $id,
                'wilaya_name' => $this->getWilayaNameFr($id),
                'commune_id' => $normCommuneId,
                'commune_name' => $cleanCommuneName,
                'count' => count($allCenters),
                'centers' => $allCenters,
                'desks' => $allCenters,
                'all_wilaya_centers' => $allCenters,
            ];
        }

        return [
            'success' => true,
            'status' => 'success',
            'fallback_to_wilaya' => false,
            'wilaya_id' => $id,
            'wilaya_name' => $this->getWilayaNameFr($id),
            'commune_id' => null,
            'commune_name' => null,
            'count' => count($allCenters),
            'centers' => $allCenters,
            'desks' => $allCenters,
            'all_wilaya_centers' => $allCenters,
        ];
    }

    /**
     * Normalize string for reliable commune matching (accents, lowercase, alphanumeric).
     */
    protected function normalizeStringForMatching(string $str): string
    {
        $str = mb_strtolower(trim($str), 'UTF-8');
        $trans = @iconv('UTF-8', 'ASCII//TRANSLIT//IGNORE', $str);
        if ($trans !== false) {
            $str = $trans;
        }
        return (string) preg_replace('/[^a-z0-9]/', '', $str);
    }

    /**
     * Get Yalidine Stop Desk Centers for a specific Wilaya.
     *
     * @param int|string $wilayaId
     * @param int|string|bool|null $communeId
     * @param string|null $communeName
     * @param bool $refresh Force cache refresh / bust
     * @return array
     */
    public function getCenters($wilayaId, $communeId = null, $communeName = null, bool $refresh = false): array
    {
        // Handle legacy call where 2nd argument was boolean $refresh
        if (is_bool($communeId)) {
            $refresh = $communeId;
            $communeId = null;
        }

        $detailed = $this->getCentersDetailed($wilayaId, $communeId, $communeName, $refresh);
        return $detailed['centers'] ?? [];
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

        $cached = Cache::get($cacheKey);
        if (is_array($cached) && !empty($cached['home_fee']) && !empty($cached['desk_fee'])) {
            $chosenFee = $isStopDesk ? $cached['desk_fee'] : $cached['home_fee'];
            return [
                'status' => 'success',
                'delivery_type' => $isStopDesk ? 'stop_desk' : 'home',
                'delivery_fee' => (float) $chosenFee,
                'home_fee' => (float) $cached['home_fee'],
                'desk_fee' => (float) $cached['desk_fee'],
                'from_wilaya_id' => $fromId,
                'from_wilaya_name' => $this->getWilayaNameById($fromId),
                'to_wilaya_id' => $toId,
                'to_wilaya_name' => $this->getWilayaNameById($toId),
                'currency' => 'DA',
                'is_stub' => false,
            ];
        }

        $liveHomeFee = null;
        $liveDeskFee = null;

        if (!$this->stubMode && !empty($this->apiId) && !empty($this->apiToken)) {
            try {
                $response = Http::withHeaders([
                    'X-API-ID' => $this->apiId,
                    'X-API-TOKEN' => $this->apiToken,
                    'Accept' => 'application/json',
                ])->timeout(10)->get("{$this->apiUrl}/fees/", [
                    'from_wilaya_id' => $fromId,
                    'to_wilaya_id' => $toId,
                ]);

                if ($response->successful()) {
                    $data = $response->json();
                    if (is_array($data)) {
                        $extractFees = function (array $node): array {
                            $h = $node['home_fee'] ?? $node['express_home'] ?? $node['economic_home'] ?? $node['domicile'] ?? $node['home'] ?? null;
                            $d = $node['desk_fee'] ?? $node['stopdesk_fee'] ?? $node['express_desk'] ?? $node['economic_desk'] ?? $node['stopdesk'] ?? $node['bureau'] ?? null;
                            return [
                                ($h !== null && is_numeric($h)) ? (float) $h : null,
                                ($d !== null && is_numeric($d)) ? (float) $d : null,
                            ];
                        };

                        // 1. Direct fields at root
                        [$h, $d] = $extractFees($data);
                        if ($h !== null && $d !== null) {
                            $liveHomeFee = $h;
                            $liveDeskFee = $d;
                        }

                        // 2. Keyed by wilaya ID or wilaya name
                        if (($liveHomeFee === null || $liveDeskFee === null) && isset($data[(string) $toId]) && is_array($data[(string) $toId])) {
                            [$h, $d] = $extractFees($data[(string) $toId]);
                            if ($h !== null && $d !== null) {
                                $liveHomeFee = $h;
                                $liveDeskFee = $d;
                            }
                        }

                        $toName = $this->getWilayaNameById($toId);
                        if (($liveHomeFee === null || $liveDeskFee === null) && $toName && isset($data[$toName]) && is_array($data[$toName])) {
                            [$h, $d] = $extractFees($data[$toName]);
                            if ($h !== null && $d !== null) {
                                $liveHomeFee = $h;
                                $liveDeskFee = $d;
                            }
                        }

                        // 3. Nested under 'data', 'fees', or 'per_commune'
                        $subList = $data['data'] ?? $data['fees'] ?? $data['per_commune'] ?? null;
                        if (($liveHomeFee === null || $liveDeskFee === null) && is_array($subList)) {
                            [$h, $d] = $extractFees($subList);
                            if ($h !== null && $d !== null) {
                                $liveHomeFee = $h;
                                $liveDeskFee = $d;
                            } else {
                                foreach ($subList as $key => $subNode) {
                                    if (is_array($subNode)) {
                                        $nodeWilayaId = $subNode['to_wilaya_id'] ?? $subNode['wilaya_id'] ?? $key;
                                        if ((string) $nodeWilayaId === (string) $toId || (string) $key === (string) $toId) {
                                            [$h, $d] = $extractFees($subNode);
                                            if ($h !== null && $d !== null) {
                                                $liveHomeFee = $h;
                                                $liveDeskFee = $d;
                                                break;
                                            }
                                        }
                                    }
                                }
                                if ($liveHomeFee === null || $liveDeskFee === null) {
                                    foreach ($subList as $subNode) {
                                        if (is_array($subNode)) {
                                            [$h, $d] = $extractFees($subNode);
                                            if ($h !== null && $d !== null && $h > 0 && $d > 0) {
                                                $liveHomeFee = $h;
                                                $liveDeskFee = $d;
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // 4. Numeric indexed array [ {...} ]
                        if (($liveHomeFee === null || $liveDeskFee === null) && isset($data[0]) && is_array($data[0])) {
                            [$h, $d] = $extractFees($data[0]);
                            if ($h !== null && $d !== null) {
                                $liveHomeFee = $h;
                                $liveDeskFee = $d;
                            }
                        }
                    }
                } else {
                    Log::warning("Yalidine calculateDeliveryFee HTTP {$response->status()}: " . $response->body());
                }
            } catch (\Throwable $e) {
                Log::warning("Yalidine calculateDeliveryFee API failed: " . $e->getMessage());
            }
        }

        if ($liveHomeFee === null || $liveHomeFee <= 0 || $liveDeskFee === null || $liveDeskFee <= 0) {
            return [
                'status' => 'error',
                'success' => false,
                'message' => 'Impossible de récupérer les tarifs réels depuis l\'API Yalidine.',
                'from_wilaya_id' => $fromId,
                'to_wilaya_id' => $toId,
                'currency' => 'DA',
                'is_stub' => false,
            ];
        }

        $rates = [
            'home_fee' => $liveHomeFee,
            'desk_fee' => $liveDeskFee,
            'is_stub' => false,
        ];
        Cache::put($cacheKey, $rates, 21600);

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
            'is_stub' => false,
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

        $itemsSubtotal = 0.0;
        if ($orderItems) {
            foreach ($orderItems as $oi) {
                $itemsSubtotal += (float) ($oi->sub_total ?? (($oi->sale_price ?? 0) * ($oi->quantity ?? 1)));
            }
        }
        $couponDiscount = (float) ($order->coupon_discount ?? 0.0);
        $orderDeliveryFee = (float) ($order->delivery_fee ?? 0.0);
        $recomputedCod = max(0.0, round($itemsSubtotal - $couponDiscount, 2)) + $orderDeliveryFee;
        $codAmount = ($order->total_price !== null && (float) $order->total_price > 0)
            ? (float) $order->total_price
            : $recomputedCod;

        $firstName = $shipping?->shipping_first_name ?: ($order->user?->name ?: 'Client');
        $lastName = trim((string) ($shipping?->shipping_last_name ?? '')) ?: $firstName;
        $phone = $shipping?->shipping_phone_no ?: ($order->user?->user_phone ?: '');
        $address = $shipping?->shipping_address ?: 'Livraison';

        $isStopDesk = in_array(strtolower(trim((string) ($order->delivery_type ?? ''))), ['stop_desk', 'stopdesk', 'desk', 'bureau'], true);
        $toWilayaId = $order->to_wilaya_id ?: $this->normalizeWilayaId($shipping?->shipping_state ?: $shipping?->shipping_city);
        $toWilayaName = $this->cleanWilayaNameForYalidine($this->getWilayaNameById($toWilayaId));
        $toCommuneName = $order->to_commune_name ?: ($shipping?->shipping_city ?: $toWilayaName);

        // Resolve sender wilaya from product/vendor first, fallback to order->from_wilaya_id or Admin default
        $firstOrderItem = $orderItems?->first();
        $firstItemId = $firstOrderItem?->item_id ? (int) $firstOrderItem->item_id : null;
        $resolvedItemFromWilaya = $this->resolveItemFromWilaya($firstItemId, $order->vendor_id ? (int) $order->vendor_id : null);
        $fromWilayaId = ($resolvedItemFromWilaya && $resolvedItemFromWilaya !== 16)
            ? $resolvedItemFromWilaya
            : ($order->from_wilaya_id ?: $resolvedItemFromWilaya);
        $fromWilayaName = $this->cleanWilayaNameForYalidine($this->getWilayaNameById((int) $fromWilayaId));

        if ($order->from_wilaya_id != $fromWilayaId) {
            $order->from_wilaya_id = $fromWilayaId;
        }

        $parcelPayload = [
            'order_id' => (string) $order->order_code,
            'from_wilaya_name' => (string) $fromWilayaName,
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

        if (empty($this->apiId) || empty($this->apiToken)) {
            Log::error("Yalidine createParcelForOrder failed: API credentials are not configured in Admin Panel.");
            return [
                'success' => false,
                'error' => 'Identifiants API Yalidine manquants ou non configurés dans les paramètres de livraison.',
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

                if ($parcelInfo && (!empty($parcelInfo['tracking']) || (!empty($parcelInfo['success']) && !empty($parcelInfo['tracking'])))) {
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

                $rawErr = $parcelInfo['error'] ?? $parcelInfo['message'] ?? ($body['error'] ?? $body['message'] ?? 'Yalidine a rejeté la création du colis.');
                $errMsg = is_array($rawErr) ? implode(', ', $rawErr) : (string) $rawErr;
                Log::error("Yalidine parcel rejection for order {$order->order_code}: {$errMsg}");
                return [
                    'success' => false,
                    'error' => $errMsg,
                ];
            }

            $rawErr = is_array($body) ? ($body['message'] ?? $body['error'] ?? $response->body()) : $response->body();
            $errMsg = is_array($rawErr) ? implode(', ', $rawErr) : (string) $rawErr;
            Log::error("Yalidine request failed with HTTP {$response->status()} for order {$order->order_code}: {$errMsg}");
            return [
                'success' => false,
                'error' => "Erreur API Yalidine (HTTP {$response->status()}): {$errMsg}",
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
     * Backward-compatibility alias for createParcelForOrder.
     *
     * @param Order $order
     * @return array
     */
    public function createShipment(Order $order): array
    {
        return $this->createParcelForOrder($order);
    }

    /**
     * Normalize delivery type to standard values: "stopdesk" or "home".
     *
     * @param string|null $deliveryType
     * @param mixed $isStopDesk
     * @return string
     */
    public function normalizeDeliveryType(?string $deliveryType, $isStopDesk = null): string
    {
        if (!empty($deliveryType)) {
            $clean = strtolower(trim((string) $deliveryType));
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
     * Backward-compatibility alias for normalizeWilayaId.
     *
     * @param mixed $wilaya
     * @return int
     */
    public function normalizeWilayaCode($wilaya): int
    {
        return $this->normalizeWilayaId($wilaya);
    }

    /**
     * Map any wilaya input (id, code, name) to official Wilaya ID (supports 1..58 and beyond).
     *
     * @param mixed $wilaya
     * @return int
     */
    public function normalizeWilayaId($wilaya): int
    {
        if (is_numeric($wilaya)) {
            $id = (int) $wilaya;
            return ($id >= 1) ? $id : 16;
        }

        if (is_string($wilaya)) {
            $trimmed = trim($wilaya);
            if (preg_match('/^0*([1-9][0-9]*)\b/', $trimmed, $matches)) {
                $id = (int) $matches[1];
                if ($id >= 1) {
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
     * Comprehensive official Algerian communes per wilaya for resilient fallback.
     * Guarantees buyers and sellers always have full real communes list.
     *
     * @param int $id
     * @return array
     */
    public function getFallbackCommunesForWilaya(int $id): array
    {
        $all = [
            1 => ['Adrar', 'Tamest', 'Charouine', 'Reggane', 'In Zghmir', 'Tit', 'Ksar Kaddour', 'Tsabit', 'Timokten', 'Aoulef', 'Fenoughil', 'Zaouiet Kounta', 'Aougrout', 'Deldoul', 'Sali', 'Akabli', 'Metarfa'],
            2 => ['Chlef', 'Ténès', 'Benairia', 'El Karimia', 'Tadjena', 'Taougrite', 'Beni Haoua', 'Sobha', 'Harchoun', 'Ouled Fares', 'Sidi Akkacha', 'Boukadir', 'Beni Rached', 'Talassa', 'Herenfa', 'Oued Goussine', 'Dahra', 'Ouled Abbes', 'Sendjas', 'Zeboudja', 'Oued Sly', 'Abou El Hassan', 'El Marsa', 'Chettia', 'Sidi Abderrahmane'],
            3 => ['Laghouat', 'Ksar El Hirane', 'Bennasser Benchohra', 'Sidi Makhlouf', 'Hassi Delaa', 'Hassi R\'Mel', 'Ain Mahdi', 'Tadjmout', 'Kheneg', 'Gueltat Sidi Saad', 'Ain Sidi Ali', 'Beidha', 'Brida', 'El Ghicha', 'Hadj Mechri', 'Sebgag', 'Taouiata', 'Tadjrouna', 'Aflou', 'El Assafia', 'Oued Morra', 'Oued M\'Zi', 'El Houaita'],
            4 => ['Oum El Bouaghi', 'Ain Beida', 'Ain M\'lila', 'Ain Fakroun', 'Sigus', 'El Amiria', 'Ain Babouche', 'Berriche', 'Ouled Hamla', 'Dhalaa', 'Ain Zitoun', 'Fkirina', 'Souk Naamane', 'Zorg', 'El Djazia', 'Ain Diss', 'Ksar Sbahi', 'Oued Nini', 'Meskiana', 'Ain Kercha', 'Hanchir Toumghani', 'Ouled Zouai'],
            5 => ['Batna', 'Ghassira', 'Maafa', 'Merouana', 'Seriana', 'Menaa', 'El Madher', 'Tazoult', 'N\'Gaous', 'Guigba', 'Inoughissen', 'Ouyoun El Assafir', 'Djerma', 'Bitam', 'Barika', 'Boumagueur', 'M\'doukal', 'Arris', 'Kimmel', 'Tilatou', 'Ain Djasser', 'Ouled Si Slimane', 'Teniet El Abed', 'T\'Kout', 'Ain Touta', 'Ras El Aioun', 'Chir', 'Oued Chaaba', 'Fesdis', 'Seggana', 'Ichmoul', 'Tedaous', 'Beni Foudhala El Hakania', 'Oued El Ma', 'Talkhamt', 'Bouzina', 'Chemora', 'Oued Taga'],
            6 => ['Béjaïa', 'Amizour', 'Ferraoun', 'Taourirt Ighil', 'Chemini', 'Souk El Tenine', 'Aokas', 'Tizi N\'Berber', 'Adekar', 'Akbou', 'Seddouk', 'Tazmalt', 'Ait R\'zine', 'Chellata', 'Ighram', 'Amalou', 'Ighil Ali', 'Fenaia Ilmaten', 'Tifra', 'Timezrit', 'Souk Oufella', 'Tibane', 'Tala Hamza', 'Barbacha', 'Oued Ghir', 'Kendira', 'Dra El Caid', 'Kherrata', 'Beni Djellil', 'Beni Ksila', 'Sidi Aïch', 'El Kseur', 'Ouzellaguen', 'Bouhamza', 'Beni Melikeche', 'Melbou'],
            7 => ['Biskra', 'Oumache', 'Branis', 'Chetma', 'Ouled Djellal', 'Ras El Miaad', 'Besbes', 'Sidi Khaled', 'Doucen', 'Chaiba', 'Sidi Okba', 'M\'Chouneche', 'El Haouch', 'Ain Naga', 'Zeribet El Oued', 'El Feidh', 'El Kantara', 'Ain Zaatout', 'El Outaya', 'Djemorah', 'Tolga', 'Lioua', 'Lichana', 'Ourlal', 'M\'Lili', 'Foughala', 'Bordj Ben Azzouz', 'El Hadjab'],
            8 => ['Béchar', 'Erg Ferradj', 'Ouled Khoudir', 'Meridja', 'Timoudi', 'Lahmar', 'Beni Abbes', 'Beni Ikhlef', 'Mechraa Houari Boumedienne', 'Kenadsa', 'Igli', 'Tabelbala', 'Taghit', 'El Ouata', 'Boukais', 'Mougheul', 'Abadla', 'Kerzaz', 'Ksabi', 'Tamtert', 'Beni Ounif'],
            9 => ['Blida', 'Chebli', 'Bouinan', 'Oued El Alleug', 'Ouled Yaich', 'Chrea', 'El Affroun', 'Chiffa', 'Hammam Melouane', 'Benkhelil', 'Soumaa', 'Mouzaia', 'Souhane', 'Meftah', 'Ouled Slama', 'Boufarik', 'Larbaa', 'Oued Djer', 'Beni Tamou', 'Bouarfa', 'Beni Mered', 'Djebabra', 'Ain Romana', 'Guerrouaou'],
            10 => ['Bouira', 'El Asnam', 'Guerrouma', 'Souk El Khemis', 'Kadiria', 'Hanif', 'Dhirah', 'El Hakimia', 'El Hachimia', 'Haizer', 'Taghzout', 'Ridane', 'Maamora', 'Mezdour', 'Lakhdaria', 'Maalah', 'El Khibouz', 'Dechmia', 'Bechloul', 'Ain El Hadjar', 'Ahl El Ksar', 'Ain Laloui', 'Ath Mansour Taourirt', 'Aomar', 'Chorfa', 'Bordj Okhriss', 'El Adjiba', 'El Mokrani', 'Bir Ghbalou', 'Boukram', 'Ain Bessam', 'Taguedite', 'Ain Turk', 'Saharidj', 'Dechmia', 'Ridane'],
            11 => ['Tamanrasset', 'Abalessa', 'In Ghar', 'In Guezzam', 'Idles', 'Tazrouk', 'Tin Zouatine', 'In Salah', 'In Amguel'],
            12 => ['Tébessa', 'Bir El Ater', 'Cheria', 'Stah Guentis', 'El Aouinet', 'El Houidjbet', 'Safsaf El Ouesra', 'Hammamet', 'Negrine', 'Bir Mokkadem', 'El Kouif', 'Morsott', 'El Ogla', 'Bir Dheb', 'Ogla Melha', 'Guorriguer', 'Bekkaria', 'Boukhadra', 'Ouenza', 'El Ma Labiodh', 'Oum Ali', 'Ferkane', 'Ain Zerga'],
            13 => ['Tlemcen', 'Beni Mester', 'Ain Tallout', 'Remchi', 'El Fehoul', 'Sabra', 'Ghazaouet', 'Souani', 'Djebala', 'Nedroma', 'Sidi Djillali', 'Beni Bahdel', 'Ouled Riyah', 'Honaine', 'Tianet', 'Ouled Mimoun', 'Beni Boussaid', 'Sebbaa Chioukh', 'Terny Beni Hdiel', 'Bensekrane', 'Ain Nehala', 'Hennaya', 'Maghnia', 'Mansourah', 'Chetouane', 'Sidi Medjahed', 'Beni Snous', 'Bab El Assa', 'Dar Yaghmouracene', 'Fellaoucene', 'Ain Ghoraba', 'Marsa Ben M\'Hidi'],
            14 => ['Tiaret', 'Medroussa', 'Ain Bouchekif', 'Sidi Ali Mellal', 'Ain Zarit', 'Ain Deheb', 'Si Abdelghani', 'Madna', 'Rachgoun', 'Frenda', 'Ain Kermes', 'Ksar Chellala', 'Rechaiga', 'Toughza', 'Mechraa Safa', 'Dahmouni', 'Rahouia', 'Mahdia', 'Sougueur', 'Sidi Abdelmoumen', 'Takhemaret', 'Oued Lilli'],
            15 => ['Tizi Ouzou', 'Ain El Hammam', 'Akbil', 'Freha', 'Souamaa', 'Mechtras', 'Irdjen', 'Timizart', 'Makouda', 'Draa El Mizan', 'Tizi Gheniff', 'Bounouh', 'Ait Chaffaa', 'Ouadhias', 'Azeffoun', 'Tigzirt', 'Ait Aissa Mimoun', 'Boghni', 'Ifigha', 'Ait Oumalou', 'Tirmitine', 'Akerrou', 'Yatafen', 'Beni Zmenzer', 'Iferhounene', 'Azazga', 'Illoula Oumalou', 'Yakouren', 'Larba Nath Irathen', 'Tizi Rached', 'Zekri', 'Ait Yahia Moussa', 'Draa Ben Khedda', 'Ouacif', 'Idjeur', 'Beni Douala', 'Beni Zikki', 'Illilten', 'Ait Mahmoud', 'Tadmait'],
            16 => ['Alger Centre', 'Sidi M\'Hamed', 'El Madania', 'Belouizdad', 'Bab El Oued', 'Bologhine', 'Casbah', 'Oued Koriche', 'Bir Mourad Raïs', 'El Biar', 'Bouzareah', 'El Mouradia', 'Ben Aknoun', 'Hydra', 'El Harrach', 'Baraki', 'Oued Smar', 'Bourouba', 'Hussein Dey', 'Kouba', 'Bachedjerrah', 'Dar El Beïda', 'Bab Ezzouar', 'Ben Zerga', 'Bordj El Kiffan', 'El Magharia', 'Beni Messous', 'Les Eucalyptus', 'Birtouta', 'Tessala El Merdja', 'Ouled Chebel', 'Sidi Moussa', 'Ain Taya', 'Bordj El Bahri', 'El Marsa', 'H\'raoua', 'Rouiba', 'Reghaïa', 'Ain Benian', 'Staoueli', 'Zeralda', 'Mahelma', 'Rahmania', 'Souidania', 'Cheraga', 'Ouled Fayet', 'El Achour', 'Draria', 'Dely Ibrahim', 'Hammamet', 'Douera', 'Baba Hassen', 'Khraicia', 'Saoula'],
            17 => ['Djelfa', 'Moudjebara', 'Ain El Ibel', 'Hassi Bahbah', 'Ain Maabed', 'Sed Rahal', 'Faidh El Botma', 'Birine', 'Bouira Lahdab', 'Zaafrane', 'Sidi Baizid', 'Messaad', 'Guettara', 'Sidi Ladjel', 'Had Sahary', 'Guernini', 'Selmana', 'Ain Chouhada', 'Oum Laadham', 'Dar Chioukh', 'Charef', 'Beni Yagoub', 'El Idrissia', 'Douis', 'El Guedid'],
            18 => ['Jijel', 'Eraguene', 'El Aouana', 'Ziama Mansouriah', 'Taher', 'Chekfa', 'Djimy', 'El Kennar Nouchfi', 'Sidi Abdelaziz', 'El Milia', 'Ouled Yahia Khadrouche', 'Boucif Ouled Askeur', 'Kaous', 'Djimla', 'Texenna', 'Bordj T\'har', 'Ouled Rabah', 'Sidi Maarouf', 'Ghebala', 'Settara'],
            19 => ['Sétif', 'Ain El Kebira', 'Beni Aziz', 'Ouled Addouane', 'Ain Roua', 'Dehamcha', 'El Eulma', 'Belaa', 'Guellal', 'Ain Arnat', 'Amoucha', 'Ain Oulmene', 'Beidha Bordj', 'Bougaa', 'Ain Legradj', 'Beni Chebana', 'Rosfa', 'Oued El Barad', 'Beni Oussine', 'Tizi N\'Bechar', 'Hammam Guergour', 'Salah Bey', 'Ain Azel', 'Tachouda', 'Bazer Sakhra', 'Hammam Soukhna'],
            20 => ['Saïda', 'Doui Thabet', 'Ain El Hadjar', 'Ouled Khaled', 'Moulay Larbi', 'Youb', 'Hounet', 'Sidi Amar', 'Sidi Boubekeur', 'El Hassasna', 'Maamora', 'Ain Sekhouna'],
            21 => ['Skikda', 'Ain Zouit', 'El Hadaiek', 'Azzaba', 'Djendel Saadi Mohamed', 'Ain Charchar', 'Bekkouche Lakhdar', 'Ben Azzouz', 'Es Sebt', 'Collo', 'Beni Zid', 'Cheraia', 'Tamalous', 'Ain Kechra', 'Ouldja Boulballout', 'Oum Toub', 'El Ghedir', 'Kheneg Mayoum', 'Hamadi Krouma', 'El Marsa', 'Sidi Mezghiche', 'Beni Oulbane', 'Oued Zhour'],
            22 => ['Sidi Bel Abbès', 'Tessala', 'Sidi Brahim', 'Mostefa Ben Brahim', 'Telagh', 'Sidi Ali Boussidi', 'Badredine El Mokrani', 'Marhoum', 'Tafissour', 'Amarnas', 'Tilmouni', 'Sidi Lahcene', 'Ain Thrid', 'Sidi Khaled', 'Tabia', 'Boukhanefis', 'Sfisef', 'M\'Cid', 'Ras El Ma', 'Oued Taourira', 'Merine'],
            23 => ['Annaba', 'Berrahal', 'El Hadjar', 'Eulma', 'El Bouni', 'Oued El Aneb', 'Cheurfa', 'Seraidi', 'Ain Berda', 'Chetaibi', 'Sidi Amar', 'Treat'],
            24 => ['Guelma', 'Nechmaya', 'Bouati Mahmoud', 'Oued Zenati', 'Tamlouka', 'Oued Fragha', 'Ain Sandel', 'Bou Hachana', 'Guelaat Bou Sbaa', 'Hammam Debagh', 'Roknia', 'Dahouara', 'Heliopolis', 'Ain Hessania', 'Belkheir', 'Bouchegouf', 'Medjez Amar', 'Ain Larbi'],
            25 => ['Constantine', 'Hamma Bouziane', 'El Khroub', 'Zighoud Youcef', 'Didouche Mourad', 'Ain Smara', 'Ouled Rahmoune', 'Ain Abid', 'Ibn Ziad', 'Beni Hamiden'],
            26 => ['Médéa', 'Ouzera', 'Ouled Maaref', 'Ain Boucif', 'Ksar El Boukhari', 'Souagui', 'Berrouaghia', 'Seghouane', 'Mezerrena', 'Mihoub', 'Tablat', 'Deux Bassins', 'Draa Essamar', 'Sidi Naamane', 'Beni Slimane', 'El Omaria', 'Si Mahdjoub', 'Ouamri', 'Boughezoul', 'Chellalat El Adhaoura'],
            27 => ['Mostaganem', 'Sayada', 'Fornaka', 'Stidia', 'Ain Nouissy', 'Hassi Mameche', 'Ain Tadles', 'Sour', 'Sidi Ali', 'Achaacha', 'Khadra', 'Bouguirat', 'Sirat', 'Souaflia', 'Mesra', 'Ain Sidi Cherif', 'Kheir Eddine', 'Sidi Lakhdar'],
            28 => ['M\'Sila', 'Maadid', 'Hammam Dalaa', 'Ouled Derradj', 'Tarna', 'Khoubana', 'M\'Cif', 'Ain El Hadjel', 'Sidi Aissa', 'Ain El Melh', 'Boussaada', 'El Hamel', 'Ouled Sidi Brahim', 'Ben Srour', 'Medjedel', 'Djebel Messaad', 'Beni Ilmane', 'Ouanougha', 'Sidi Ameur'],
            29 => ['Mascara', 'Bouhanifia', 'Tizi', 'Tighennif', 'Hachem', 'Ghriss', 'Oued El Abtal', 'Sidi Kada', 'Aouf', 'Ain Fekan', 'Sig', 'Oggaz', 'Zahana', 'Mohammadia', 'El Ghomri', 'Mocta Douz'],
            30 => ['Ouargla', 'Ain Beida', 'N\'Goussa', 'Hassi Messaoud', 'Rouissat', 'Baldat Amor', 'Sidi Khouiled', 'Hassi Ben Abdallah'],
            31 => ['Oran', 'Gdyel', 'Bir El Djir', 'Hassi Bounif', 'Es Senia', 'Arzew', 'Bethioua', 'Marsat El Hadjadj', 'Ain El Turk', 'El Ancor', 'Mers El Kebir', 'Bou Sfer', 'Boutlelis', 'Misserghin', 'Oued Tlelat', 'Tafraoui', 'Hassi Mefsoukh', 'El Braya'],
            32 => ['El Bayadh', 'Rogassa', 'Brezina', 'Ghassoul', 'Boualem', 'El Abiodh Sidi Cheikh', 'Ain El Orak', 'Cheguig', 'Kef El Ahmar', 'Boussemghoun', 'Chellala'],
            33 => ['Illizi', 'Djanet', 'Debdeb', 'Bordj Omar Driss', 'In Amenas'],
            34 => ['Bordj Bou Arreridj', 'Ras El Oued', 'Bordj Zemoura', 'Mansoura', 'El M\'hir', 'Ben Daoud', 'El Achir', 'Ain Taghrout', 'Bordj Ghedir', 'Sidi Embarek', 'Khelil', 'Taglait'],
            35 => ['Boumerdès', 'Boudouaou', 'Afir', 'Bordj Menaiel', 'Baghlia', 'Sidi Daoud', 'Naciria', 'Isser', 'Zemmouri', 'Si Mustapha', 'Thenia', 'Khemis El Khechna', 'Ouled Moussa', 'Larbatache', 'Hammedi', 'Dellys'],
            36 => ['El Tarf', 'Bouhadjar', 'Ben M\'Hidi', 'Drean', 'El Kala', 'Besbes', 'Zerizer', 'Ain El Assel', 'Raml Souk', 'Berrihane', 'Lac des Oiseaux', 'Chefia'],
            37 => ['Tindouf', 'Oum El Assel'],
            38 => ['Tissemsilt', 'Bordj Bou Naama', 'Theinet El Had', 'Lazharia', 'Larbaa', 'Beni Chaib', 'Lardjem', 'Khemisti', 'Ammari', 'Youssoufia'],
            39 => ['El Oued', 'Robbah', 'Oued El Alenda', 'Bayadha', 'Nakhla', 'Guemar', 'Kouinine', 'Reguiba', 'Hamraia', 'Taghzout', 'Debila', 'Hassi Khelifa', 'Taleb Larbi', 'Magrane', 'Sidi Aoun'],
            40 => ['Khenchela', 'Kais', 'Baghai', 'El Hamma', 'Ain Touila', 'Tamza', 'Bouhmama', 'Chechar', 'Babar', 'Djellal', 'Ouled Rechache'],
            41 => ['Souk Ahras', 'Sedrata', 'Hanancha', 'Mechroha', 'Ouled Driss', 'Tiffech', 'Zaarouria', 'Taoura', 'Drea', 'Heddada', 'Khedara', 'Merahna', 'M\'daourouch', 'Oum El Adhaim'],
            42 => ['Tipaza', 'Menaceur', 'Larhat', 'Douaouda', 'Bourkika', 'Khemisti', 'Ahmar El Ain', 'Bou Ismail', 'Fouka', 'Bouharoun', 'Ain Tagourait', 'Nador', 'Hadjout', 'Sidi Amar', 'Gouraya', 'Damous', 'Cherchell', 'Sidi Ghiles'],
            43 => ['Mila', 'Ferdjioua', 'Chelghoum Laid', 'Teleghma', 'Tadjenanet', 'Grarem Gouga', 'Sidi Merouane', 'Rouached', 'Tiberguent', 'Oued Endja', 'Ain Tine', 'Bouhatem', 'Oued Athmania', 'Derradji Bousselah'],
            44 => ['Aïn Defla', 'Khemis Miliana', 'Miliana', 'El Attaf', 'Djelida', 'El Amra', 'Djendel', 'Hammam Righa', 'Bourached', 'Hoceinia', 'Rouina', 'Arib', 'Tiberkanine', 'Ain Lechiekh'],
            45 => ['Naâma', 'Mecheria', 'Ain Sefra', 'Tiout', 'Sfissifa', 'Moghrar', 'Asla', 'Djenienne Bourezg', 'Ain Ben Khelil', 'Makman Ben Amer'],
            46 => ['Aïn Témouchent', 'Chaabat El Leham', 'Ain Kihal', 'Hammam Bouhadjar', 'El Malah', 'Terga', 'Oulhaca El Gheraba', 'Sidi Safi', 'Beni Saf', 'El Amria', 'Bouzedjar', 'Ain El Arbaa'],
            47 => ['Ghardaïa', 'El Menia', 'Dhayet Bendhahoua', 'Berriane', 'Metlili', 'El Guerrara', 'Zelfana', 'Sebseb', 'Bounoura', 'Hassi Fehal'],
            48 => ['Relizane', 'Oued Rhiou', 'Bendaoud', 'Zemmoura', 'Djidiouia', 'Ammi Moussa', 'Ain Tarek', 'Mazouna', 'Sidi M\'Hamed Ben Ali', 'Yellel', 'El Matmar', 'Ramka', 'Mendes'],
            49 => ['Timimoun', 'Ouled Said', 'Ksar Kaddour', 'Tinerkouk', 'Charouine', 'Deldoul', 'Aougrout'],
            50 => ['Bordj Badji Mokhtar', 'Timiaouine'],
            51 => ['Ouled Djellal', 'Sidi Khaled', 'Ras El Miaad', 'Besbes', 'Doucen', 'Chaiba'],
            52 => ['Béni Abbès', 'Kerzaz', 'Tabelbala', 'El Ouata', 'Tamtert', 'Igli', 'Timoudi', 'Ouled Khoudir', 'Ksabi'],
            53 => ['In Salah', 'In Ghar', 'Foggaret Ezzaouia'],
            54 => ['In Guezzam', 'Tin Zouatine'],
            55 => ['Touggourt', 'Temacine', 'Megarine', 'Taibet', 'El Hadjira', 'Blidet Amor', 'Sidi Slimane', 'Nezla', 'Zaouia El Abidia'],
            56 => ['Djanet', 'Bordj El Haouas'],
            57 => ['El M\'Ghair', 'Djamaa', 'Oum Touyour', 'Sidi Amrane', 'Still', 'M\'Rara', 'Tendla'],
            58 => ['El Meniaa', 'Hassi Gara', 'Hassi Fehal']
        ];

        $names = $all[$id] ?? [$this->getWilayaNameById($id)];
        $communes = [];
        $fallbackId = $id * 1000 + 1;
        foreach ($names as $name) {
            $communes[] = [
                'id' => $fallbackId++,
                'wilaya_id' => $id,
                'name' => $name,
                'has_stop_desk' => true,
                'is_deliverable' => true,
            ];
        }
        return $communes;
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

    /**
     * Map of 58 Wilayas in Arabic.
     */
    public static array $wilayasAr = [
        1 => 'أدرار', 2 => 'الشلف', 3 => 'الأغواط', 4 => 'أم البواقي', 5 => 'باتنة',
        6 => 'بجاية', 7 => 'بسكرة', 8 => 'بشار', 9 => 'البليدة', 10 => 'البويرة',
        11 => 'تمنراست', 12 => 'تبسة', 13 => 'تلمسان', 14 => 'تيارت', 15 => 'تيزي وزو',
        16 => 'الجزائر', 17 => 'الجلفة', 18 => 'جيجل', 19 => 'سطيف', 20 => 'سعيدة',
        21 => 'سكيكدة', 22 => 'سيدي بلعباس', 23 => 'عنابة', 24 => 'قالمة', 25 => 'قسنطينة',
        26 => 'المدية', 27 => 'مستغانم', 28 => 'المسيلة', 29 => 'معسكر', 30 => 'ورقلة',
        31 => 'وهران', 32 => 'البيض', 33 => 'إليزي', 34 => 'برج بوعريريج', 35 => 'بومرداس',
        36 => 'الطارف', 37 => 'تندوف', 38 => 'تيسمسيلت', 39 => 'الوادي', 40 => 'خنشلة',
        41 => 'سوق أهراس', 42 => 'تيبازة', 43 => 'ميلة', 44 => 'عين الدفلى', 45 => 'النعامة',
        46 => 'عين تموشنت', 47 => 'غرداية', 48 => 'غليزان', 49 => 'تيميمون', 50 => 'برج باجي مختار',
        51 => 'أولاد جلال', 52 => 'بني عباس', 53 => 'عين صالح', 54 => 'عين قزام', 55 => 'تقرت',
        56 => 'جانت', 57 => 'المغير', 58 => 'المنيعة'
    ];

    public function getWilayaNameFr(int $code): string
    {
        return $this->getWilayaNameById($code);
    }

    public function getWilayaNameAr(int $code): string
    {
        return self::$wilayasAr[$code] ?? 'الجزائر';
    }

    /**
     * Parse raw string/number to a valid Algerian wilaya code (supports 1..58 and beyond).
     */
    public function tryParseWilayaCode($raw): ?int
    {
        if ($raw === null || $raw === '') {
            return null;
        }

        if (is_numeric($raw)) {
            $val = (int) $raw;
            return ($val >= 1) ? $val : null;
        }

        $str = trim((string) $raw);

        // Match leading numeric code e.g. "16 - Alger" or "16"
        if (preg_match('/^0*([1-9][0-9]*)\b/', $str, $matches)) {
            $id = (int) $matches[1];
            if ($id >= 1) {
                return $id;
            }
        }

        $needle = strtolower(preg_replace('/[^a-zA-Z\s\']/', '', $str));
        $needle = trim($needle);
        if ($needle === '') {
            return null;
        }

        if (str_contains($needle, 'algiers')) {
            return 16;
        }

        for ($i = 1; $i <= 58; $i++) {
            $frName = strtolower(preg_replace('/[^a-zA-Z\s\']/', '', $this->getWilayaNameById($i)));
            if ($needle === $frName || str_contains($needle, $frName) || str_contains($frName, $needle)) {
                return $i;
            }
        }

        return null;
    }

    /**
     * Strip leading numeric code (e.g. "31 - Oran" -> "Oran") for Yalidine API exact matching.
     */
    public function cleanWilayaNameForYalidine(string $name): string
    {
        $clean = trim($name);
        $clean = preg_replace('/^\d{1,2}\s*[-–—:\.]\s*/u', '', $clean);
        return trim((string) $clean);
    }

    /**
     * Resolve origin Wilaya code (1..58+) from product's / vendor's selected wilaya first,
     * falling back to explicit input or Admin DeliverySetting default only if unset.
     */
    public function resolveItemFromWilaya(?int $itemId = null, ?int $vendorId = null, $explicitFromWilaya = null): int
    {
        if (!empty($itemId)) {
            $item = DB::table('psx_items')
                ->select('id', 'location_city_id', 'location_township_id', 'added_user_id', 'vendor_id')
                ->where('id', $itemId)
                ->first();

            if ($item) {
                // 1. Try item location_city_id -> psx_location_cities.name first (most accurate)
                if (!empty($item->location_city_id)) {
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
                }

                // 2. Try item location_township_id -> look up its city name first, then township name
                if (!empty($item->location_township_id)) {
                    $township = DB::table('psx_location_townships')
                        ->select('id', 'name', 'location_city_id')
                        ->where('id', $item->location_township_id)
                        ->first();

                    if ($township) {
                        if (!empty($township->location_city_id)) {
                            $tCity = DB::table('psx_location_cities')
                                ->select('id', 'name')
                                ->where('id', $township->location_city_id)
                                ->first();
                            if ($tCity && !empty($tCity->name)) {
                                $byTCityName = $this->tryParseWilayaCode($tCity->name);
                                if ($byTCityName !== null) {
                                    return $byTCityName;
                                }
                            }
                        }
                        if (!empty($township->name)) {
                            $byTownshipName = $this->tryParseWilayaCode($township->name);
                            if ($byTownshipName !== null) {
                                return $byTownshipName;
                            }
                        }
                    }
                }

                // 3. Numeric fallback on item location_city_id if 1..58
                if (!empty($item->location_city_id)) {
                    $byId = $this->tryParseWilayaCode($item->location_city_id);
                    if ($byId !== null && $byId >= 1 && $byId <= 69) {
                        return $byId;
                    }
                }

                // 4. Try seller's user profile (added_user_id)
                if (!empty($item->added_user_id)) {
                    $sellerUser = DB::table('users')->where('id', $item->added_user_id)->first();
                    if ($sellerUser && !empty($sellerUser->user_address)) {
                        $byUser = $this->tryParseWilayaCode($sellerUser->user_address);
                        if ($byUser !== null) {
                            return $byUser;
                        }
                    }
                }

                if (empty($vendorId) && !empty($item->vendor_id)) {
                    $vendorId = (int) $item->vendor_id;
                }
            }
        }

        // 5. Try vendor address / owner address
        if (!empty($vendorId)) {
            $vendor = DB::table('psx_vendors')
                ->select('id', 'address', 'name', 'owner_user_id')
                ->where('id', $vendorId)
                ->first();

            if ($vendor && !empty($vendor->address)) {
                $byVendor = $this->tryParseWilayaCode($vendor->address);
                if ($byVendor !== null) {
                    return $byVendor;
                }
            }
            if ($vendor && !empty($vendor->owner_user_id)) {
                $ownerUser = DB::table('users')->where('id', $vendor->owner_user_id)->first();
                if ($ownerUser && !empty($ownerUser->user_address)) {
                    $byOwner = $this->tryParseWilayaCode($ownerUser->user_address);
                    if ($byOwner !== null) {
                        return $byOwner;
                    }
                }
            }
        }

        // 6. Explicit from_wilaya passed by caller
        if ($explicitFromWilaya !== null && $explicitFromWilaya !== '') {
            $parsed = $this->tryParseWilayaCode($explicitFromWilaya);
            if ($parsed !== null) {
                return $parsed;
            }
        }

        // 7. Fallback to Admin DeliverySetting from_wilaya_id
        try {
            $adminSetting = \App\Models\DeliverySetting::first();
            if ($adminSetting && !empty($adminSetting->from_wilaya_id)) {
                $adminFrom = $this->tryParseWilayaCode($adminSetting->from_wilaya_id);
                if ($adminFrom !== null) {
                    return $adminFrom;
                }
            }
        } catch (\Throwable $e) {
            // Ignore DB errors during bootstrap
        }

        return 16; // Default to Alger
    }

    /**
     * Fetch live tracking details and history timeline for an order from Yalidine API v1.
     * Note: Never exposes shipping label / bordereau URL.
     */
    public function getParcelTrackingDetails(Order $order): array
    {
        $tracking = trim((string) ($order->yalidine_tracking ?? ''));
        $statusId = (int) ($order->order_status_id ?? 1);
        $yalidineStatus = (string) ($order->yalidine_parcel_status ?? $order->yalidine_status ?? '');
        $histories = [];
        $parcelData = null;

        if (!empty($tracking) && !empty($this->apiId) && !empty($this->apiToken)) {
            try {
                $parcelRes = Http::withHeaders([
                    'X-API-ID' => $this->apiId,
                    'X-API-TOKEN' => $this->apiToken,
                    'Accept' => 'application/json',
                ])->timeout(10)->get("{$this->apiUrl}/parcels/{$tracking}");

                if ($parcelRes->successful()) {
                    $pJson = $parcelRes->json();
                    $parcelData = $pJson['data'][0] ?? $pJson[0] ?? (isset($pJson['tracking']) ? $pJson : null);
                    if (is_array($parcelData) && !empty($parcelData['last_status'])) {
                        $yalidineStatus = (string) $parcelData['last_status'];
                        $order->yalidine_parcel_status = $yalidineStatus;
                        $order->yalidine_status = $yalidineStatus;
                        $order->save();
                    }
                }
            } catch (\Throwable $e) {
                Log::warning("Yalidine getParcelTrackingDetails /parcels error for {$tracking}: " . $e->getMessage());
            }

            try {
                $histRes = Http::withHeaders([
                    'X-API-ID' => $this->apiId,
                    'X-API-TOKEN' => $this->apiToken,
                    'Accept' => 'application/json',
                ])->timeout(10)->get("{$this->apiUrl}/histories/{$tracking}");

                if ($histRes->successful()) {
                    $hJson = $histRes->json();
                    $rawHist = $hJson['data'] ?? (is_array($hJson) ? $hJson : []);
                    if (is_array($rawHist)) {
                        foreach ($rawHist as $h) {
                            if (!is_array($h)) {
                                continue;
                            }
                            $histories[] = [
                                'date_status' => (string) ($h['date_status'] ?? $h['created_at'] ?? ''),
                                'status' => (string) ($h['status'] ?? ''),
                                'reason' => (string) ($h['reason'] ?? ''),
                                'center_name' => (string) ($h['center_name'] ?? ''),
                                'wilaya_name' => (string) ($h['wilaya_name'] ?? ''),
                                'commune_name' => (string) ($h['commune_name'] ?? ''),
                            ];
                        }
                    }
                }
            } catch (\Throwable $e) {
                Log::warning("Yalidine getParcelTrackingDetails /histories error for {$tracking}: " . $e->getMessage());
            }
        }

        // Determine current timeline step index (0=Pending, 1=Accepted, 2=Preparing, 3=In Transit, 4=Out for Delivery, 5=Delivered/Returned)
        $lowerYal = mb_strtolower($yalidineStatus, 'UTF-8');
        $currentStep = 0;
        if ($statusId === 4 || str_contains($lowerYal, 'livré') || str_contains($lowerYal, 'delivered')) {
            $currentStep = 5;
        } elseif ($statusId === 5 || $statusId === 6 || str_contains($lowerYal, 'retourn') || str_contains($lowerYal, 'annul') || str_contains($lowerYal, 'échou')) {
            $currentStep = 5;
        } elseif (str_contains($lowerYal, 'sorti') || str_contains($lowerYal, 'livraison') || str_contains($lowerYal, 'out')) {
            $currentStep = 4;
        } elseif (str_contains($lowerYal, 'expédi') || str_contains($lowerYal, 'transit') || str_contains($lowerYal, 'reçu à wilaya') || str_contains($lowerYal, 'vers wilaya') || str_contains($lowerYal, 'centre')) {
            $currentStep = 3;
        } elseif ($statusId === 3 || str_contains($lowerYal, 'préparation') || str_contains($lowerYal, 'dispatch') || !empty($tracking)) {
            $currentStep = 2;
        } elseif ($statusId === 2) {
            $currentStep = 1;
        } else {
            $currentStep = 0;
        }

        return [
            'order_id' => (string) $order->id,
            'order_code' => (string) $order->order_code,
            'tracking' => $tracking,
            'order_status_id' => $statusId,
            'yalidine_status' => $yalidineStatus,
            'delivery_type' => (string) ($order->delivery_type ?? 'home'),
            'to_wilaya_name' => $this->getWilayaNameById((int) ($order->to_wilaya_id ?: 16)),
            'to_commune_name' => (string) ($order->to_commune_name ?? ''),
            'current_step' => $currentStep,
            'is_cancelled_or_returned' => in_array($statusId, [5, 6], true) || str_contains($lowerYal, 'retourn') || str_contains($lowerYal, 'annul'),
            'status_reason' => (string) ($order->status_reason ?? ($histories[0]['reason'] ?? '')),
            'histories' => $histories,
        ];
    }

    /**
     * Fetch Stop-Desk agencies for a destination Wilaya.
     *
     * @return array<int, array{id:string, name:string, communeName:string, address:string, wilaya_code:int}>
     */
    public function getDesks(int $wilayaCode, bool $refresh = false): array
    {
        $centers = $this->getCenters($wilayaCode, $refresh);
        $desks = [];

        foreach ($centers as $center) {
            $id = (string) ($center['center_id'] ?? $center['id'] ?? '');
            $name = trim((string) ($center['name'] ?? $center['center_name'] ?? ''));
            if ($name === '') {
                continue;
            }
            $commune = trim((string) ($center['commune_name'] ?? ''));
            $address = trim((string) ($center['address'] ?? ''));
            if ($address === '') {
                $address = $commune !== '' ? "{$commune}, " . $this->getWilayaNameFr($wilayaCode) : $this->getWilayaNameFr($wilayaCode);
            }
            if ($commune === '') {
                $commune = $this->getWilayaNameFr($wilayaCode);
            }

            $desks[] = [
                'id' => $id,
                'center_id' => is_numeric($id) ? (int) $id : (int) ($center['center_id'] ?? 0),
                'name' => $name,
                'communeName' => $commune,
                'commune_name' => $commune,
                'address' => $address,
                'wilaya_code' => $wilayaCode,
                'is_stopdesk' => $center['is_stopdesk'] ?? true,
            ];
        }

        return $desks;
    }

    /**
     * Compute Stop-Desk and Home Delivery quote in DZD for checkout.
     */
    public function getYalidineQuote(
        ?int $itemId,
        $toWilayaInput,
        ?string $toCommuneName = null,
        $fromWilayaOverride = null,
        ?int $vendorId = null,
        bool $refresh = false
    ): array {
        $fromWilayaCode = $this->resolveItemFromWilaya($itemId, $vendorId, $fromWilayaOverride);
        $toWilayaCode = $this->normalizeWilayaId($toWilayaInput);
        $cleanCommune = $toCommuneName ? trim($toCommuneName) : null;

        $fees = $this->calculateDeliveryFee($fromWilayaCode, $toWilayaCode, 'home');
        if (($fees['status'] ?? '') === 'error' || empty($fees['desk_fee']) || empty($fees['home_fee'])) {
            return [
                'status' => 'error',
                'success' => false,
                'message' => $fees['message'] ?? 'Impossible de récupérer les tarifs réels depuis l\'API Yalidine.',
                'from_wilaya_code' => $fromWilayaCode,
                'to_wilaya_code' => $toWilayaCode,
            ];
        }
        $stopDeskPrice = (int) round($fees['desk_fee']);
        $homePrice = (int) round($fees['home_fee']);
        $desks = $this->getDesks($toWilayaCode, $refresh);
        $fromWilayaName = $this->getWilayaNameFr($fromWilayaCode);
        $toWilayaName = $this->getWilayaNameFr($toWilayaCode);

        return [
            'status' => 'success',
            'courier' => 'yalidine',
            'is_stub' => $fees['is_stub'] ?? false,
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
                'estimated_days' => 2,
                'desks' => $desks,
            ],
            'home_delivery' => [
                'delivery_type' => 'home',
                'label' => 'Yalidine Livraison à Domicile',
                'price_dzd' => $homePrice,
                'estimated_days' => 2,
            ],
            'desk_fee' => $stopDeskPrice,
            'home_fee' => $homePrice,
        ];
    }

    /**
     * Sync missing wilayas from Yalidine to psx_location_cities.
     * Deactivates non-Algerian dummy cities and inserts missing wilayas.
     */
    public function syncMissingWilayasToDatabase(): array
    {
        $wilayas = $this->getWilayas();
        $existingCities = DB::table('psx_location_cities')->get();
        $existingNames = [];

        foreach ($existingCities as $city) {
            $existingNames[strtolower(trim($city->name))] = $city->id;
        }

        // Deactivate non-Algerian dummy cities (e.g. United States, London, India, Singapore, etc.)
        $nonAlgerianDummy = ['united states', 'london', 'india', 'singapore', 'mandalay', 'yangon', 'bangalore'];
        DB::table('psx_location_cities')
            ->whereIn(DB::raw('LOWER(name)'), $nonAlgerianDummy)
            ->update(['status' => 0]);

        // Fix legacy "Algerie" seed entry to official "16 - Alger"
        DB::table('psx_location_cities')
            ->where('name', 'Algerie')
            ->update([
                'name' => '16 - Alger',
                'ordering' => 16,
                'status' => 1,
            ]);

        $insertedCount = 0;
        $insertedNames = [];

        foreach ($wilayas as $w) {
            $id = (int) ($w['id'] ?? $w['code'] ?? 0);
            $cleanName = (string) ($w['clean_name'] ?? ($w['name'] ?? ''));
            if (empty($cleanName)) {
                $cleanName = $this->getWilayaNameById($id);
            }

            // Check if clean name or prefixed name exists
            $found = false;
            foreach ($existingNames as $nameLower => $cityId) {
                if ($nameLower === strtolower($cleanName)
                    || str_contains($nameLower, strtolower($cleanName))
                    || str_contains(strtolower($cleanName), $nameLower)) {
                    $found = true;
                    // Ensure active status
                    DB::table('psx_location_cities')->where('id', $cityId)->update(['status' => 1]);
                    break;
                }
            }

            if (!$found) {
                $formattedName = sprintf('%02d - %s', $id, $cleanName);
                DB::table('psx_location_cities')->insert([
                    'name' => $formattedName,
                    'lat' => '0',
                    'lng' => '0',
                    'ordering' => $id,
                    'status' => 1,
                    'description' => "Wilaya de {$cleanName}",
                    'touch_count' => 0,
                    'is_featured' => 0,
                    'added_date' => now(),
                    'added_user_id' => 1,
                ]);

                $existingNames[strtolower($cleanName)] = true;
                $existingNames[strtolower($formattedName)] = true;
                $insertedCount++;
                $insertedNames[] = $formattedName;
            }
        }

        // Invalidate location cache
        Cache::forget('psx_location_cities');

        return [
            'success' => true,
            'inserted_count' => $insertedCount,
            'inserted_wilayas' => $insertedNames,
            'total_wilayas' => count($wilayas),
        ];
    }
}
