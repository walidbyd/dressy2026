<?php

namespace Modules\StoreFront\VendorPanel\Http\Controllers\Backend\Controllers\DeliverySetting;

use App\Http\Controllers\Controller;
use App\Models\DeliverySetting;
use App\Services\YalidineService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Inertia\Inertia;
use Modules\Core\Constants\Constants;
use Modules\StoreFront\VendorPanel\Entities\Order;

class AdminDeliverySettingController extends Controller
{
    public function index()
    {
        $setting = DeliverySetting::getSettings();
        $yalidineService = app(YalidineService::class);

        // Mask token for display
        $rawToken = $setting->api_token;
        $maskedToken = '';
        if (!empty($rawToken)) {
            $maskedToken = strlen($rawToken) > 6
                ? '••••••••••••' . substr($rawToken, -4)
                : '••••••••••••';
        }

        $settingsData = [
            'id' => $setting->id,
            'is_enabled' => (bool) $setting->is_enabled,
            'environment' => (string) $setting->environment,
            'api_base_url' => (string) $setting->api_base_url,
            'api_id' => (string) ($setting->api_id ?? ''),
            'api_token' => $maskedToken,
            'is_token_set' => !empty($rawToken),
            'auto_create_parcel' => (bool) $setting->auto_create_parcel,
            'auto_sync_trigger' => (string) $setting->auto_sync_trigger,
            'auto_sync_status' => (bool) $setting->auto_sync_status,
            'webhook_secret' => (string) ($setting->webhook_secret ?? ''),
            'webhook_url' => url('/api/v1.0/delivery/yalidine/webhook'),
            'sender_name' => (string) $setting->sender_name,
            'sender_phone' => (string) $setting->sender_phone,
            'from_wilaya_id' => (int) $setting->from_wilaya_id,
            'from_commune_name' => (string) ($setting->from_commune_name ?? ''),
            'from_stop_desk_id' => (string) ($setting->from_stop_desk_id ?? ''),
            'default_delivery_type' => (string) $setting->default_delivery_type,
            'is_free_shipping' => (bool) $setting->is_free_shipping,
            'free_shipping_min_amount' => (float) ($setting->free_shipping_min_amount ?? 0),
            'has_insurance' => (bool) $setting->has_insurance,
            'open_parcel' => (bool) $setting->open_parcel,
            'description_prefix' => (string) $setting->description_prefix,
        ];

        // Fetch wilayas list
        $wilayas = $yalidineService->getWilayas();

        // Calculate Yalidine logistics stats
        $stats = [
            'total_shipments' => Order::whereNotNull('yalidine_tracking')->count(),
            'in_transit' => Order::whereNotNull('yalidine_tracking')
                ->whereIn('order_status_id', [Constants::orderDeliveringStatus, Constants::orderApprovedStatus])
                ->count(),
            'delivered' => Order::whereNotNull('yalidine_tracking')
                ->where('order_status_id', Constants::orderDeliveredStatus)
                ->count(),
            'returned_or_cancelled' => Order::whereNotNull('yalidine_tracking')
                ->whereIn('order_status_id', [Constants::orderCancelledStatus, Constants::orderReturnedStatus])
                ->count(),
        ];

        return Inertia::render('admin/delivery/Index', [
            'settings' => $settingsData,
            'wilayas' => $wilayas,
            'stats' => $stats,
        ]);
    }

    public function update(Request $request)
    {
        $request->validate([
            'is_enabled' => 'required|boolean',
            'environment' => 'required|in:production,sandbox',
            'api_base_url' => 'required|url',
            'api_id' => 'nullable|string|max:100',
            'api_token' => 'nullable|string|max:500',
            'auto_create_parcel' => 'required|boolean',
            'auto_sync_trigger' => 'required|in:on_order_placed,on_seller_confirmed,manual_only',
            'auto_sync_status' => 'required|boolean',
            'webhook_secret' => 'nullable|string|max:100',
            'sender_name' => 'required|string|max:150',
            'sender_phone' => 'required|string|max:50',
            'from_wilaya_id' => 'required|integer|min:1|max:58',
            'from_commune_name' => 'nullable|string|max:150',
            'from_stop_desk_id' => 'nullable|string|max:50',
            'default_delivery_type' => 'required|in:home,stop_desk',
            'is_free_shipping' => 'required|boolean',
            'free_shipping_min_amount' => 'nullable|numeric|min:0',
            'has_insurance' => 'required|boolean',
            'open_parcel' => 'required|boolean',
            'description_prefix' => 'nullable|string|max:150',
        ]);

        $setting = DeliverySetting::getSettings();

        $data = $request->except(['api_token']);

        // Only update api_token if a new, unmasked token is provided
        $newToken = trim((string) $request->input('api_token', ''));
        if (!empty($newToken) && !str_starts_with($newToken, '••••')) {
            $setting->api_token = $newToken;
        }

        $setting->fill($data);
        $setting->save();

        // Clear cached delivery services
        Cache::forget('yalidine_wilayas_v1');
        Cache::forget('dzship:yalidine:wilayas:v1');

        return redirect()->back()->with('status', __('Paramètres de livraison Yalidine enregistrés avec succès !'));
    }

    public function testConnection(Request $request)
    {
        $setting = DeliverySetting::getSettings();

        $apiId = trim((string) $request->input('api_id', $setting->api_id));
        $apiTokenInput = trim((string) $request->input('api_token', ''));

        // If input token is masked or empty, use stored token
        $apiToken = (!empty($apiTokenInput) && !str_starts_with($apiTokenInput, '••••'))
            ? $apiTokenInput
            : $setting->api_token;

        $baseUrl = rtrim((string) $request->input('api_base_url', $setting->api_base_url ?: 'https://api.yalidine.app/v1'), '/');

        if (empty($apiId) || empty($apiToken)) {
            return response()->json([
                'success' => false,
                'message' => __('Veuillez renseigner à la fois votre API ID et votre API Token Yalidine avant de tester la connexion.'),
            ], 422);
        }

        try {
            $response = Http::withHeaders([
                'X-API-ID' => $apiId,
                'X-API-TOKEN' => $apiToken,
                'Accept' => 'application/json',
            ])->timeout(12)->get("{$baseUrl}/wilayas/");

            if ($response->successful()) {
                $json = $response->json();
                $data = $json['data'] ?? $json;
                $count = is_array($data) ? count($data) : 0;

                return response()->json([
                    'success' => true,
                    'message' => "Connexion réussie ! L'API Yalidine a répondu positivement ({$count} wilayas récupérées). Vos identifiants sont valides.",
                    'wilayas_count' => $count,
                ]);
            }

            $errMsg = $response->json()['message'] ?? "Erreur HTTP {$response->status()} reçue de Yalidine.";
            return response()->json([
                'success' => false,
                'message' => "Échec de connexion à l'API Yalidine : {$errMsg}",
            ], 422);
        } catch (\Throwable $e) {
            Log::warning('Yalidine test connection error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => "Impossible de contacter l'API Yalidine : " . $e->getMessage(),
            ], 422);
        }
    }

    public function syncFees(Request $request)
    {
        try {
            // Invalidate cached wilayas and rates
            Cache::forget('yalidine_wilayas_v1');
            Cache::forget('dzship:yalidine:wilayas:v1');

            $yalidine = app(YalidineService::class);
            $wilayas = $yalidine->getWilayas();

            return response()->json([
                'success' => true,
                'message' => 'Tarifs et ' . count($wilayas) . ' wilayas Yalidine synchronisés et mis en cache avec succès !',
                'count' => count($wilayas),
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'success' => false,
                'message' => 'Erreur de synchronisation : ' . $e->getMessage(),
            ], 422);
        }
    }
}
