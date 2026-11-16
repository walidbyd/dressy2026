<?php

namespace Modules\StoreFront\VendorPanel\Transformers\Api\App\V1_0\Order;

use Illuminate\Http\Resources\Json\JsonResource;
use Modules\Core\Transformers\Api\App\V1_0\CoreImage\CoreImageApiResource;
use stdClass;

class OrderHistoryApiResource extends JsonResource
{
    public function toArray($request)
    {

        $itemInfoArr = [];
        $currencySymbol = $this->vendorTransaction?->currency?->currency_symbol;
        $totalAmount = $currencySymbol.$this->total_price;

        $discountPriceArr = [];
        $subTotalPriceArr = [];

        foreach ($this->orderItems as $orderItem) {
            $itemInfoObj = new stdClass;
            $itemInfoObj->item_id = (string) $orderItem->item_id;
            $itemInfoObj->item_name = (string) $orderItem->item_name;
            $itemInfoObj->original_price = (string) $currencySymbol.$orderItem->original_price;
            $itemInfoObj->sale_price = (string) $currencySymbol.$orderItem->sale_price;
            $itemInfoObj->discount_price = (string) $this->vendorTransaction?->currency?->currency_symbol.$orderItem->discount_price;
            $itemInfoObj->quantity = (string) $orderItem->quantity;
            $itemInfoObj->sub_total = (string) $this->vendorTransaction?->currency?->currency_symbol.$orderItem->sub_total;
            $itemInfoObj->default_photo = new CoreImageApiResource(isset($orderItem->item->cover[0]) && $orderItem->item->cover[0] ? $orderItem->item->cover[0] : []);
            array_push($itemInfoArr, $itemInfoObj);
            array_push($discountPriceArr, $orderItem->discount_price);
            array_push($subTotalPriceArr, $orderItem->sub_total);
        }

        return [
            'id' => (string) $this->id,
            'order_status_id' => (string) $this->order_status_id,
            'order_code' => (string) $this->order_code,
            'order_date' => (string) \Carbon\Carbon::parse($this->order_date)->format('M d, Y'),
            'payment_status' => (string) $this->vendorTransaction?->vendorPaymentStatus?->name,
            'payment_status_color' => (string) $this->vendorTransaction?->vendorPaymentStatus?->colour,
            'order_status' => (string) $this->orderStatus?->name,
            'order_status_color' => (string) $this->orderStatus?->colour,
            'status_reason' => (string) ($this->status_reason ?? ''),
            'payment_date' => isset($this->vendorTransaction?->payment_date) ? (string) \Carbon\Carbon::parse($this->vendorTransaction?->payment_date)->format('M d, Y') : '',
            'vendor_name' => (string) $this->vendor?->name,
            'item_info' => $itemInfoArr,
            'item_count' => count($itemInfoArr),
            'total' => (string) $totalAmount,
            'delivery_fee' => (string) ($this->delivery_fee ?? '0'),
            'delivery_type' => (string) ($this->delivery_type ?? 'home'),
            'yalidine_tracking' => (string) ($this->yalidine_tracking ?? ''),
            'yalidine_label_url' => (string) ($this->yalidine_label_url ?? ''),
            'yalidine_status' => (string) ($this->yalidine_parcel_status ?? $this->yalidine_status ?? ''),
            'yalidine_parcel_status' => (string) ($this->yalidine_parcel_status ?? $this->yalidine_status ?? ''),
            'from_wilaya_id' => (string) ($this->from_wilaya_id ?? ''),
            'to_wilaya_id' => (string) ($this->to_wilaya_id ?? ''),
            'to_commune_name' => (string) ($this->to_commune_name ?? ''),
            'yalidine_stop_desk_id' => (string) ($this->yalidine_stop_desk_id ?? ''),
            'user_id' => (string) $this->user_id,
            'buyer_user_id' => (string) $this->user_id,
            'seller_user_id' => (string) ($this->vendor?->owner_user_id ?? ''),
            'vendor_id' => (string) ($this->vendor_id ?? ''),
        ];

    }

    // public function toResponse($request)
    // {
    //     return $this->resource->response()->getData(true);
    // }
}
