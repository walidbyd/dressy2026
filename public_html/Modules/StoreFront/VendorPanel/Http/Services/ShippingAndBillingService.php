<?php

namespace Modules\StoreFront\VendorPanel\Http\Services;

use App\Config\ps_constant;
use App\Http\Services\PsService;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Modules\Core\Constants\Constants;
use Modules\Core\Http\Services\UserAccessApiTokenService;
use Modules\Core\Http\Services\VendorService;
use Modules\StoreFront\VendorPanel\Entities\Order;
use Modules\StoreFront\VendorPanel\Entities\OrderItem;
use Modules\StoreFront\VendorPanel\Entities\ShippingAndBilling;
use Modules\StoreFront\VendorPanel\Entities\VendorDeliverySetting;
use Modules\StoreFront\VendorPanel\Http\Services\YalidineService;

class ShippingAndBillingService extends PsService
{
    protected $userAccessApiTokenService;

    protected $vendorService;

    public function __construct(UserAccessApiTokenService $userAccessApiTokenService, VendorService $vendorService)
    {
        $this->userAccessApiTokenService = $userAccessApiTokenService;
        $this->vendorService = $vendorService;
    }

    public function storeShippingAndBillingInfoFromApi($request)
    {

        // / check permission start
        $deviceToken = $request->header(ps_constant::deviceTokenKeyFromApi);
        $userId = $request->login_user_id;

        // user token layer permission start
        $userAccessApiToken = $this->userAccessApiTokenService->getUserAccessApiToken($userId, $deviceToken);
        // user token layer permission end

        if (empty($userAccessApiToken) && !\App\Models\User::where('id', $userId)->exists()) {
            $msg = __('shipping_and_billing__api_store_info_no_permission', [], $request->language_symbol);

            return responseMsgApi($msg, Constants::forbiddenStatusCode);
        }
        // / check permission end

        // Ensure vendor_id is properly populated from items or seller's vendor
        if (empty($request->vendor_id) || $request->vendor_id == 0) {
            if (!empty($request->order_summary) && is_array($request->order_summary)) {
                $firstSummary = (object) $request->order_summary[0];
                $firstItem = DB::table('psx_items')->where('id', $firstSummary->item_id ?? null)->first();
                if ($firstItem) {
                    if (!empty($firstItem->vendor_id) && $firstItem->vendor_id > 0) {
                        $request->merge(['vendor_id' => $firstItem->vendor_id]);
                    } elseif (!empty($firstItem->added_user_id)) {
                        $sellerVendor = DB::table('psx_vendors')->where('owner_user_id', $firstItem->added_user_id)->first();
                        if ($sellerVendor) {
                            $request->merge(['vendor_id' => $sellerVendor->id]);
                        } else {
                            $sellerUser = DB::table('users')->where('id', $firstItem->added_user_id)->first();
                            $sellerName = $sellerUser ? ($sellerUser->name ?? 'Seller Store') : 'Seller Store';
                            $newVendorId = DB::table('psx_vendors')->insertGetId([
                                'name' => $sellerName,
                                'owner_user_id' => $firstItem->added_user_id,
                                'status' => 2, // active
                                'currency_id' => 16, // DZD
                                'added_date' => Carbon::now(),
                                'added_user_id' => $firstItem->added_user_id,
                            ]);
                            $request->merge(['vendor_id' => $newVendorId]);
                        }
                    }
                }
            }
        }

        if (empty($request->vendor_id)) {
            $firstVendor = DB::table('psx_vendors')->first();
            $request->merge(['vendor_id' => $firstVendor ? $firstVendor->id : 1]);
        }

        // check vendor currency
        $vendor = $this->vendorService->getVendor($request->vendor_id);
        if ($vendor && empty($vendor->currency_id)) {
            $vendor->currency_id = 16;
            $vendor->save();
        }

        // check quantity enough or not start
        if (! empty($request->order_summary) && is_array($request->order_summary)) {
            foreach ($request->order_summary as $orderSummary) {
                $orderSummary = (object) $orderSummary;
                $itemId = $orderSummary->item_id ?? null;
                if (! $itemId) {
                    continue;
                }
                $requestedQty = max(1, (int) ($orderSummary->quantity ?? 1));
                $availableQty = availableQuantityFromItem($itemId);

                $item = DB::table('psx_items')->where('id', $itemId)->first();
                if ($item && (int) ($item->is_sold_out ?? 0) === 1) {
                    $msg = __('this_item_does_not_have_quantity_you_want', [], $request->language_symbol);

                    return responseMsgApi($msg, Constants::badRequestStatusCode);
                }

                if ($availableQty < $requestedQty) {
                    $msg = __('this_item_does_not_have_quantity_you_want', [], $request->language_symbol);

                    return responseMsgApi($msg, Constants::badRequestStatusCode);
                }
            }
        }
        // check quantity enough or not end

        DB::beginTransaction();
        try {

            $shippingInfoForNextTime = (int) ($request->is_save_shipping_info_for_next_time ?? 0);
            $billingInfoForNextTime = (int) ($request->is_save_billing_info_for_next_time ?? 0);

            // Resolve Yalidine delivery type, origin wilaya (from item), destination wilaya & commune/stop-desk
            $dzshipService = app(\App\Services\DzshipYalidineService::class);
            $deliveryType = $dzshipService->normalizeDeliveryType($request->delivery_type, $request->is_stop_desk ?? null);
            $isStopDesk = ($deliveryType === 'stopdesk');

            $firstItemId = null;
            if (is_array($request->order_summary) && !empty($request->order_summary)) {
                $firstSummary = (object) $request->order_summary[0];
                $firstItemId = isset($firstSummary->item_id) ? (int) $firstSummary->item_id : null;
            }

            $fromWilayaId = $dzshipService->resolveItemFromWilaya(
                $firstItemId,
                $request->vendor_id ? (int) $request->vendor_id : null,
                $request->from_wilaya_id
            );

            $toWilayaRaw = $request->to_wilaya_id
                ?? $request->wilaya_code
                ?? $request->shipping_state
                ?? $request->shipping_city
                ?? 16;
            $toWilayaId = $dzshipService->normalizeWilayaCode($toWilayaRaw);
            $toWilayaName = $dzshipService->getWilayaNameFr($toWilayaId);

            $rawStopDeskId = $request->yalidine_stop_desk_id ?? $request->stop_desk_id ?? $request->stopdesk_id ?? null;
            $stopDeskId = null;
            $stopDeskName = trim((string) ($request->stop_desk_name ?? ''));
            $toCommuneName = trim((string) ($request->to_commune_name ?? $request->commune_name ?? $request->shipping_city ?? ''));

            if ($isStopDesk) {
                $desks = $dzshipService->getDesks($toWilayaId);
                $matchedDesk = null;
                if ($rawStopDeskId !== null && $rawStopDeskId !== '') {
                    foreach ($desks as $desk) {
                        if ((string) ($desk['id'] ?? '') === (string) $rawStopDeskId ||
                            (string) ($desk['center_id'] ?? '') === (string) $rawStopDeskId) {
                            $matchedDesk = $desk;
                            break;
                        }
                    }
                }
                if ($matchedDesk !== null) {
                    $rawStopDeskId = (string) ($matchedDesk['center_id'] ?? $matchedDesk['id'] ?? $rawStopDeskId);
                    if ($stopDeskName === '') {
                        $stopDeskName = (string) ($matchedDesk['name'] ?? '');
                    }
                    if (!empty($matchedDesk['communeName'])) {
                        $toCommuneName = (string) $matchedDesk['communeName'];
                    } elseif (!empty($matchedDesk['commune_name'])) {
                        $toCommuneName = (string) $matchedDesk['commune_name'];
                    }
                } elseif (($rawStopDeskId === null || $rawStopDeskId === '') && !empty($desks)) {
                    $matchedDesk = $desks[0];
                    $rawStopDeskId = (string) ($matchedDesk['center_id'] ?? $matchedDesk['id'] ?? '');
                    if ($stopDeskName === '') {
                        $stopDeskName = (string) ($matchedDesk['name'] ?? '');
                    }
                    if (!empty($matchedDesk['communeName'])) {
                        $toCommuneName = (string) $matchedDesk['communeName'];
                    }
                }
                if ($rawStopDeskId !== null && $rawStopDeskId !== '') {
                    $digitsOnly = preg_replace('/\D+/', '', (string) $rawStopDeskId);
                    $stopDeskId = ($digitsOnly !== '') ? (int) $digitsOnly : null;
                }
            }

            if ($toCommuneName === '') {
                $toCommuneName = $toWilayaName;
            }

            if ($request->has('delivery_fee') && is_numeric($request->delivery_fee) && (float) $request->delivery_fee > 0) {
                $deliveryFee = (float) $request->delivery_fee;
            } else {
                $quote = $dzshipService->getYalidineQuote(
                    $firstItemId,
                    $toWilayaId,
                    $toCommuneName,
                    $fromWilayaId,
                    $request->vendor_id ? (int) $request->vendor_id : null
                );
                $deliveryFee = (float) ($isStopDesk
                    ? ($quote['stop_desk']['price_dzd'] ?? $quote['desk_fee'] ?? 400)
                    : ($quote['home_delivery']['price_dzd'] ?? $quote['home_fee'] ?? 600));
            }

            // Calculate items subtotal
            $itemsSubtotal = 0;
            if (is_array($request->order_summary)) {
                foreach ($request->order_summary as $sumItem) {
                    $sumObj = (object) $sumItem;
                    $itemsSubtotal += (float) ($sumObj->sub_total ?? (($sumObj->sale_price ?? 0) * ($sumObj->quantity ?? 1)));
                }
            }

            $computedTotalPrice = (float) $request->total_price;
            if ($computedTotalPrice < ($itemsSubtotal + $deliveryFee)) {
                $computedTotalPrice = $itemsSubtotal + $deliveryFee;
            }

            // Resolve recipient name, phone, email, and auto-composed address (no street address required)
            $buyerUser = DB::table('users')->select('id', 'name', 'email', 'user_phone')->where('id', $userId)->first();
            $rawFullName = trim((string) ($request->recipient_name ?? ''));
            $firstName = trim((string) ($request->shipping_first_name ?? ''));
            $lastName = trim((string) ($request->shipping_last_name ?? ''));

            if ($firstName === '' && $rawFullName !== '') {
                $parts = preg_split('/\s+/', $rawFullName, 2);
                $firstName = $parts[0] ?? $rawFullName;
                $lastName = $parts[1] ?? '';
            }
            if ($firstName === '') {
                $firstName = trim((string) ($buyerUser->name ?? 'Client Dressy'));
            }
            if ($lastName === '') {
                // Split multi-word first name cleanly if provided in a single "Full Name" field
                if (str_contains($firstName, ' ')) {
                    $parts = preg_split('/\s+/', $firstName, 2);
                    $firstName = $parts[0];
                    $lastName = $parts[1] ?? '-';
                } else {
                    $lastName = '-';
                }
            }

            $phoneNo = trim((string) ($request->shipping_phone_no ?? $request->phone ?? $buyerUser->user_phone ?? ''));
            $email = trim((string) ($request->shipping_email ?? $buyerUser->email ?? ''));
            if ($email === '') {
                $email = "buyer{$userId}@dressy-dz.com";
            }

            $autoComposedAddress = $isStopDesk && $stopDeskName !== ''
                ? "{$stopDeskName}, {$toWilayaName}"
                : "{$toCommuneName}, {$toWilayaName}";
            $shippingAddress = trim((string) ($request->shipping_address ?? '')) !== ''
                ? trim((string) $request->shipping_address)
                : $autoComposedAddress;
            $shippingCountry = trim((string) ($request->shipping_country ?? '')) ?: 'Algeria';
            $shippingState = trim((string) ($request->shipping_state ?? '')) ?: $toWilayaName;
            $shippingCity = trim((string) ($request->shipping_city ?? '')) ?: $toCommuneName;
            $shippingPostalCode = trim((string) ($request->shipping_postal_code ?? '')) ?: sprintf('%02d000', $toWilayaId);

            // save in psx_orders table
            $order = new Order;
            $order->user_id = $userId;
            $order->vendor_id = $request->vendor_id;
            $order->total_price = $computedTotalPrice;
            $order->order_status_id = ps_constant::pendingStatusOfVendorOrder;
            $order->order_code = rand(100000, 999999);
            $order->delivery_fee = $deliveryFee;
            $order->wallet_amount_used = max(0, (float) ($request->wallet_amount_used ?? 0));
            $order->delivery_type = $deliveryType;
            $order->from_wilaya_id = $fromWilayaId;
            $order->to_wilaya_id = $toWilayaId;
            $order->to_commune_name = $toCommuneName;
            $order->yalidine_stop_desk_id = $stopDeskId;
            $order->is_payment_fail = 1; // update it after transaction success
            $order->order_date = Carbon::now();
            $order->added_user_id = $userId;
            $order->save();

            // save in psx_order_items table
            foreach ($request->order_summary as $orderSummary) {
                $orderSummary = (object) $orderSummary;
                $orderItem = new OrderItem;
                $orderItem->order_id = $order->id;
                $orderItem->item_id = $orderSummary->item_id;
                $orderItem->quantity = $orderSummary->quantity;
                $orderItem->original_price = $orderSummary->original_price;
                $orderItem->sale_price = $orderSummary->sale_price;
                $orderItem->sub_total = $orderSummary->sub_total;
                $orderItem->discount_price = $orderSummary->discount_price;
                $orderItem->added_user_id = $userId;
                $orderItem->save();
            }

            // save in psx_shipping_and_billings table (all NOT NULL fields guaranteed populated)
            $shippingAndBilling = new ShippingAndBilling;
            $shippingAndBilling->order_id = $order->id;
            $shippingAndBilling->shipping_first_name = $firstName;
            $shippingAndBilling->shipping_last_name = $lastName;
            $shippingAndBilling->shipping_email = $email;
            $shippingAndBilling->shipping_phone_no = $phoneNo;
            $shippingAndBilling->shipping_address = $shippingAddress;
            $shippingAndBilling->shipping_country = $shippingCountry;
            $shippingAndBilling->shipping_state = $shippingState;
            $shippingAndBilling->shipping_city = $shippingCity;
            $shippingAndBilling->shipping_postal_code = $shippingPostalCode;
            $shippingAndBilling->is_save_shipping_info_for_next_time = $shippingInfoForNextTime;
            $shippingAndBilling->billing_first_name = trim((string) ($request->billing_first_name ?? '')) ?: $firstName;
            $shippingAndBilling->billing_last_name = trim((string) ($request->billing_last_name ?? '')) ?: $lastName;
            $shippingAndBilling->billing_email = trim((string) ($request->billing_email ?? '')) ?: $email;
            $shippingAndBilling->billing_phone_no = trim((string) ($request->billing_phone_no ?? '')) ?: $phoneNo;
            $shippingAndBilling->billing_address = trim((string) ($request->billing_address ?? '')) ?: $shippingAddress;
            $shippingAndBilling->billing_country = trim((string) ($request->billing_country ?? '')) ?: $shippingCountry;
            $shippingAndBilling->billing_state = trim((string) ($request->billing_state ?? '')) ?: $shippingState;
            $shippingAndBilling->billing_city = trim((string) ($request->billing_city ?? '')) ?: $shippingCity;
            $shippingAndBilling->billing_postal_code = trim((string) ($request->billing_postal_code ?? '')) ?: $shippingPostalCode;
            $shippingAndBilling->is_save_billing_info_for_next_time = $billingInfoForNextTime;
            $shippingAndBilling->added_user_id = $userId;
            $shippingAndBilling->save();

            DB::commit();
        } catch (\Throwable $e) {

            DB::rollBack();
            $msg = __('shipping_and_billing__api_store_info_error', [], $request->language_symbol);

            return responseMsgApi($e->getMessage(), Constants::badRequestStatusCode);
        }
        $data = [
            'order_id' => (string) $order->id,
        ];

        return responseDataApi($data, Constants::okStatusCode);
    }
}
