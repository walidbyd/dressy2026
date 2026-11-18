<?php

namespace Modules\StoreFront\VendorPanel\Http\Controllers\Backend\Rests\App\V1_0\ShippingAndBilling;

use Illuminate\Contracts\Translation\Translator;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Validator;
use Modules\Core\Constants\Constants;
use Modules\StoreFront\VendorPanel\Http\Services\ShippingAndBillingService;

class ShippingAndBillingApiController extends Controller
{
    protected $shippingAndBillingService;

    protected $translator;

    public function __construct(Translator $translator, ShippingAndBillingService $shippingAndBillingService)
    {
        $this->shippingAndBillingService = $shippingAndBillingService;
        $this->translator = $translator;
    }

    public function storeShippingAndBillingInfo(Request $request)
    {
        // Address-free Yalidine checkout validation:
        // Only require vendor, recipient name, phone, wilaya, delivery items, and total price.
        // Street address, postal code, building, and separate billing fields are strictly optional.
        $validator = Validator::make($request->all(), [
            'vendor_id' => 'required|exists:psx_vendors,id',
            'shipping_first_name' => 'required_without:recipient_name',
            'recipient_name' => 'nullable|string|max:120',
            'shipping_last_name' => 'nullable|string|max:120',
            'shipping_email' => 'nullable|email',
            'shipping_phone_no' => 'required_without:phone',
            'phone' => 'nullable|string|max:30',
            'shipping_address' => 'nullable|string|max:255',
            'shipping_country' => 'nullable|string|max:100',
            'shipping_state' => 'nullable|string|max:120',
            'shipping_city' => 'nullable|string|max:120',
            'shipping_postal_code' => 'nullable|string|max:30',
            'to_wilaya_id' => 'required_without_all:wilaya_code,shipping_state,shipping_city',
            'wilaya_code' => 'nullable',
            'to_commune_name' => 'nullable|string|max:120',
            'delivery_type' => 'nullable|string|max:20',
            'yalidine_stop_desk_id' => 'nullable',
            'stop_desk_name' => 'nullable|string|max:160',
            'billing_first_name' => 'nullable|string|max:120',
            'billing_last_name' => 'nullable|string|max:120',
            'billing_email' => 'nullable|email',
            'billing_phone_no' => 'nullable|string|max:30',
            'billing_address' => 'nullable|string|max:255',
            'billing_country' => 'nullable|string|max:100',
            'billing_state' => 'nullable|string|max:120',
            'billing_city' => 'nullable|string|max:120',
            'billing_postal_code' => 'nullable|string|max:30',
            'order_summary' => 'required|array|min:1',
            'order_summary.*.item_id' => 'required|exists:psx_items,id',
            'order_summary.*.quantity' => 'required',
            'order_summary.*.original_price' => 'required',
            'order_summary.*.sale_price' => 'required',
            'order_summary.*.sub_total' => 'required',
            'order_summary.*.discount_price' => 'required',
            'total_price' => 'required',
        ]);

        if ($request->language_symbol) {
            $this->translator->setLocale($request->language_symbol);
            $validator->setTranslator($this->translator);
        }

        if ($validator->fails()) {
            return responseMsgApi(implode("\n", Arr::flatten($validator->getMessageBag()->getMessages())), Constants::badRequestStatusCode);
        }
        // / validation end

        $ShippingAndbillingInfo = $this->shippingAndBillingService->storeShippingAndBillingInfoFromApi($request);

        return $ShippingAndbillingInfo;
    }
}
