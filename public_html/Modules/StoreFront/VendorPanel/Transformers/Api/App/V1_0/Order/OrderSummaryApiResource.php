<?php

namespace Modules\StoreFront\VendorPanel\Transformers\Api\App\V1_0\Order;

use Illuminate\Http\Resources\Json\JsonResource;
use Modules\Core\Transformers\Api\App\V1_0\CoreImage\CoreImageApiResource;
use stdClass;

class OrderSummaryApiResource extends JsonResource
{
    public function toArray($request)
    {
        $itemInfoArr = [];
        $currencySymbol = $this->vendorTransaction?->currency?->currency_symbol ?? 'DA ';
        $paymentAmount = $this->vendorTransaction?->payment_amount ?? $this->total_price ?? 0;
        $totalAmount = $currencySymbol.$paymentAmount;
        $deliveryFee = $currencySymbol.($this->delivery_fee ?? 0);

        $discountPriceArr = [];
        $subTotalPriceArr = [];

        if (!empty($this->orderItems)) {
            foreach ($this->orderItems as $orderItem) {
                $itemInfoObj = new stdClass;
                $itemInfoObj->item_id = (string) $orderItem->item_id;
                $itemInfoObj->item_name = (string) $orderItem->item_name;
                $itemInfoObj->original_price = (string) $currencySymbol.$orderItem->original_price;
                $itemInfoObj->sale_price = (string) $currencySymbol.$orderItem->sale_price;
                $itemInfoObj->discount_price = (string) $currencySymbol.$orderItem->discount_price;
                $itemInfoObj->quantity = (string) $orderItem->quantity;
                $itemInfoObj->sub_total = (string) $currencySymbol.$orderItem->sub_total;
                $defaultPhoto = (isset($orderItem->item?->cover[0]) && $orderItem->item?->cover[0]) ? $orderItem->item->cover[0] : [];
                $itemInfoObj->default_photo = new CoreImageApiResource($defaultPhoto);
                array_push($itemInfoArr, $itemInfoObj);
                array_push($discountPriceArr, (float) ($orderItem->discount_price ?? 0));
                array_push($subTotalPriceArr, (float) ($orderItem->sub_total ?? 0));
            }
        }

        $allItemSubTotalFromCart = $currencySymbol.round(array_sum($subTotalPriceArr), 2);
        $allItemDiscountFromCart = $currencySymbol.round(array_sum($discountPriceArr), 2);

        $orderSummaryObj = new stdClass;
        $orderSummaryObj->id = (string) $this->id;
        $orderSummaryObj->order_status_id = (string) $this->order_status_id;
        $orderSummaryObj->order_code = (string) $this->order_code;
        $orderSummaryObj->shipping_first_name = (string) ($this->shippingAndBilling?->shipping_first_name ?? '');
        $orderSummaryObj->shipping_last_name = (string) ($this->shippingAndBilling?->shipping_last_name ?? '');
        $orderSummaryObj->shipping_email = (string) ($this->shippingAndBilling?->shipping_email ?? '');
        $orderSummaryObj->shipping_phone_no = (string) ($this->shippingAndBilling?->shipping_phone_no ?? '');
        $orderSummaryObj->shipping_address = (string) ($this->shippingAndBilling?->shipping_address ?? '');
        $orderSummaryObj->shipping_country = (string) ($this->shippingAndBilling?->shipping_country ?? '');
        $orderSummaryObj->shipping_state = (string) ($this->shippingAndBilling?->shipping_state ?? '');
        $orderSummaryObj->shipping_city = (string) ($this->shippingAndBilling?->shipping_city ?? '');
        $orderSummaryObj->shipping_postal_code = (string) ($this->shippingAndBilling?->shipping_postal_code ?? '');
        $orderSummaryObj->is_save_shipping_info_for_next_time = (string) ($this->shippingAndBilling?->is_save_shipping_info_for_next_time ?? '');
        $orderSummaryObj->billing_first_name = (string) ($this->shippingAndBilling?->billing_first_name ?? '');
        $orderSummaryObj->billing_last_name = (string) ($this->shippingAndBilling?->billing_last_name ?? '');
        $orderSummaryObj->billing_email = (string) ($this->shippingAndBilling?->billing_email ?? '');
        $orderSummaryObj->billing_phone_no = (string) ($this->shippingAndBilling?->billing_phone_no ?? '');
        $orderSummaryObj->billing_address = (string) ($this->shippingAndBilling?->billing_address ?? '');
        $orderSummaryObj->billing_country = (string) ($this->shippingAndBilling?->billing_country ?? '');
        $orderSummaryObj->billing_state = (string) ($this->shippingAndBilling?->billing_state ?? '');
        $orderSummaryObj->billing_city = (string) ($this->shippingAndBilling?->billing_city ?? '');
        $orderSummaryObj->billing_postal_code = (string) ($this->shippingAndBilling?->billing_postal_code ?? '');
        $orderSummaryObj->is_save_billing_info_for_next_time = (string) ($this->shippingAndBilling?->is_save_billing_info_for_next_time ?? '');
        $isDelivered = ((int) $this->order_status_id === 4);
        $isPaid = ($this->vendorTransaction?->vendorPaymentStatus?->id == 2)
            || (($this->payment_status ?? '') === 'paid')
            || ((int) ($this->is_wallet_credited ?? 0) === 1);
        $isDeliveredAndPaid = ($isDelivered && $isPaid);

        $locale = app()->getLocale() ?: ($request->language_symbol ?? 'fr');
        $deliveredAndPaidLabel = match(strtolower(substr($locale, 0, 2))) {
            'ar' => 'تم التوصيل والدفع',
            'en' => 'Delivered & Paid',
            default => 'Livré et payé',
        };

        $orderSummaryObj->payment_method = (string) ($this->vendorTransaction?->payment_method ?? 'COD');
        $orderSummaryObj->payment_status = (string) ($this->vendorTransaction?->vendorPaymentStatus?->name ?? 'En attente');
        $orderSummaryObj->payment_status_color = (string) ($this->vendorTransaction?->vendorPaymentStatus?->colour ?? '#F59E0B');
        $orderSummaryObj->order_status = $isDeliveredAndPaid ? $deliveredAndPaidLabel : (string) ($this->orderStatus?->name ?? 'En attente');
        $orderSummaryObj->order_status_color = $isDeliveredAndPaid ? '#10B981' : (string) ($this->orderStatus?->colour ?? '#F59E0B');
        $orderSummaryObj->is_delivered_and_paid = $isDeliveredAndPaid ? '1' : '0';
        $orderSummaryObj->delivered_and_paid_label = $isDeliveredAndPaid ? $deliveredAndPaidLabel : (string) ($this->orderStatus?->name ?? 'En attente');
        $orderSummaryObj->payment_date = !empty($this->vendorTransaction?->payment_date) ? (string) \Carbon\Carbon::parse($this->vendorTransaction->payment_date)->format('M d, Y') : '';
        $orderSummaryObj->vendor_name = (string) ($this->vendorTransaction?->vendor?->name ?? $this->vendor?->name ?? '');
        $orderSummaryObj->item_info = $itemInfoArr;
        $orderSummaryObj->sub_total = (string) $allItemSubTotalFromCart;
        $orderSummaryObj->total_discount = (string) $allItemDiscountFromCart;
        $orderSummaryObj->delivery_fee = (string) $deliveryFee;
        $orderSummaryObj->total = (string) $totalAmount;
        $requestingUserId = $request->login_user_id
            ?? $request->user_id
            ?? $request->header('login-user-id')
            ?? ($request->user()?->id);

        $vendorOwnerId = $this->vendor?->owner_user_id;
        if (!$vendorOwnerId && $this->vendor_id) {
            $vendorOwnerId = \Modules\Core\Entities\Vendor\Vendor::where('id', $this->vendor_id)->value('owner_user_id');
        }

        $isSeller = (!empty($requestingUserId) && !empty($vendorOwnerId) && (int) $vendorOwnerId === (int) $requestingUserId);
        $isAdmin = false;
        if ($request->user() && ($request->user()->is_admin || $request->user()->role_id == 1)) {
            $isAdmin = true;
        }

        // Bordereau d'envoi privacy: ONLY vendor owner and admin can see the shipping label URL.
        // Buyers can only see the tracking number and delivery status.
        $labelUrl = ($isSeller || $isAdmin) ? (string) ($this->yalidine_label_url ?? '') : '';

        $orderSummaryObj->yalidine_tracking = (string) ($this->yalidine_tracking ?? '');
        $orderSummaryObj->yalidine_parcel_id = (string) ($this->yalidine_parcel_id ?? '');
        $orderSummaryObj->yalidine_status = (string) ($this->yalidine_parcel_status ?? $this->yalidine_status ?? '');
        $orderSummaryObj->yalidine_parcel_status = (string) ($this->yalidine_parcel_status ?? $this->yalidine_status ?? '');
        $orderSummaryObj->yalidine_label_url = $labelUrl;
        $orderSummaryObj->delivery_type = (string) ($this->delivery_type ?? 'home');
        $orderSummaryObj->from_wilaya_id = (string) ($this->from_wilaya_id ?? '');
        $orderSummaryObj->to_wilaya_id = (string) ($this->to_wilaya_id ?? '');
        $orderSummaryObj->to_commune_name = (string) ($this->to_commune_name ?? '');
        $orderSummaryObj->yalidine_stop_desk_id = (string) ($this->yalidine_stop_desk_id ?? '');
        $orderSummaryObj->status_reason = (string) ($this->status_reason ?? '');
        $orderSummaryObj->fulfillment_deadline_at = !empty($this->fulfillment_deadline_at)
            ? (string) \Carbon\Carbon::parse($this->fulfillment_deadline_at)->toIso8601String()
            : '';
        $orderSummaryObj->is_wallet_credited = (string) ($this->is_wallet_credited ?? '0');
        $orderSummaryObj->wallet_credited_at = isset($this->wallet_credited_at) ? (string) \Carbon\Carbon::parse($this->wallet_credited_at)->format('M d, Y H:i') : '';
        $orderSummaryObj->user_id = (string) $this->user_id;
        $orderSummaryObj->buyer_user_id = (string) $this->user_id;
        $orderSummaryObj->seller_user_id = (string) ($vendorOwnerId ?? $this->vendor?->owner_user_id ?? '');
        $orderSummaryObj->vendor_id = (string) ($this->vendor_id ?? '');
        $orderSummaryObj->is_reviewed = (string) ($this->is_reviewed ?? '0');
        $orderSummaryObj->review_rating = (string) ($this->review_rating ?? '');

        return [
            'order_summary' => $orderSummaryObj,
        ];
    }
}
