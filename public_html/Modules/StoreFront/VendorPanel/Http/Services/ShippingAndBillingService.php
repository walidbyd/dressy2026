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
        foreach ($request->order_summary as $orderSummary) {
            $orderSummary = (object) $orderSummary;
            $itemId = $orderSummary->item_id;
            if (availableQuantityFromItem($itemId) < (int) $orderSummary->quantity) {
                $msg = __('this_item_does_not_have_quantity_you_want', [], $request->language_symbol);

                return responseMsgApi($msg, Constants::badRequestStatusCode);
            }
        }
        // check quantity enough or not end

        DB::beginTransaction();
        try {

            $shippingInfoForNextTime = $request->is_save_shipping_info_for_next_time;
            $billingInfoForNextTime = $request->is_save_billing_info_for_next_time;

            if ($request->has('delivery_fee') && is_numeric($request->delivery_fee) && (float) $request->delivery_fee > 0) {
                $deliveryFee = (float) $request->delivery_fee;
            } else {
                $VendorDeliverySetting = VendorDeliverySetting::where(VendorDeliverySetting::vendorId, $request->vendor_id)->first();
                if (! empty($VendorDeliverySetting) && ! empty($VendorDeliverySetting->delivery_setting)) {
                    $deliveryFee = (float) $VendorDeliverySetting->delivery_charges;
                } else {
                    // Compute dynamic Yalidine delivery fee
                    $vendor = DB::table('psx_vendors')->where('id', $request->vendor_id)->first();
                    $fromWilaya = $vendor ? ($vendor->address ?? $vendor->name ?? 16) : 16;
                    $toWilaya = $request->shipping_city ?? $request->shipping_state ?? 16;
                    $isStopDesk = filter_var($request->is_stop_desk ?? false, FILTER_VALIDATE_BOOLEAN);
                    $yalidineService = app(YalidineService::class);
                    $calc = $yalidineService->calculateDeliveryFee($fromWilaya, $toWilaya, $isStopDesk);
                    $deliveryFee = (float) ($calc['delivery_fee'] ?? 400.00);
                }
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

            // save in psx_orders table
            $order = new Order;
            $order->user_id = $userId;
            $order->vendor_id = $request->vendor_id;
            $order->total_price = $computedTotalPrice;
            $order->order_status_id = ps_constant::pendingStatusOfVendorOrder;
            $order->order_code = rand(100000, 999999);
            $order->delivery_fee = $deliveryFee;
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

            // save in psx_shipping_and_billings table
            $shippingAndBilling = new ShippingAndBilling;
            $shippingAndBilling->order_id = $order->id;
            $shippingAndBilling->shipping_first_name = $request->shipping_first_name;
            $shippingAndBilling->shipping_last_name = $request->shipping_last_name;
            $shippingAndBilling->shipping_email = $request->shipping_email;
            $shippingAndBilling->shipping_phone_no = $request->shipping_phone_no;
            $shippingAndBilling->shipping_address = $request->shipping_address;
            $shippingAndBilling->shipping_country = $request->shipping_country;
            $shippingAndBilling->shipping_state = $request->shipping_state;
            $shippingAndBilling->shipping_city = $request->shipping_city;
            $shippingAndBilling->shipping_postal_code = $request->shipping_postal_code;
            $shippingAndBilling->is_save_shipping_info_for_next_time = $request->is_save_shipping_info_for_next_time;
            $shippingAndBilling->billing_first_name = $request->billing_first_name;
            $shippingAndBilling->billing_last_name = $request->billing_last_name;
            $shippingAndBilling->billing_email = $request->billing_email;
            $shippingAndBilling->billing_phone_no = $request->billing_phone_no;
            $shippingAndBilling->billing_address = $request->billing_address;
            $shippingAndBilling->billing_country = $request->billing_country;
            $shippingAndBilling->billing_state = $request->billing_state;
            $shippingAndBilling->billing_city = $request->billing_city;
            $shippingAndBilling->billing_postal_code = $request->billing_postal_code;
            $shippingAndBilling->is_save_billing_info_for_next_time = $request->is_save_billing_info_for_next_time;
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
