<?php

namespace Modules\StoreFront\VendorPanel\Transformers\Api\App\V1_0\Vendor;

use Illuminate\Http\Resources\Json\JsonResource;
use Modules\Core\Constants\Constants;
use Modules\Core\Entities\Vendor\Vendor;
use Modules\Core\Entities\VendorPayment;
use Modules\Core\Entities\VendorPaymentInfo;
use Modules\StoreFront\VendorPanel\Entities\VendorDeliverySetting;

class VendorConfigInfoApiResource extends JsonResource
{
    public function toArray($request)
    {
        $vendorId = $request->vendor_id ?? $this->resource;

        $vendor = $vendorId ? Vendor::where(Vendor::id, $vendorId)->first() : null;
        $currency_id = $vendor ? (string) ($vendor->currency_id ?? '') : '';

        $VendorDeliverySetting = $vendorId ? VendorDeliverySetting::where(VendorDeliverySetting::vendorId, $vendorId)->first() : null;
        $deliverySetting = new \stdClass;
        $deliverySetting->delivery_setting = isset($VendorDeliverySetting) ? (string) $VendorDeliverySetting->delivery_setting : '0';
        $deliverySetting->delivery_charges = isset($VendorDeliverySetting) ? (string) $VendorDeliverySetting->delivery_charges : '0';

        $getPaymentStatus = function ($paymentId) use ($vendorId) {
            if (! $vendorId) {
                return '0';
            }
            $vp = VendorPayment::where(VendorPayment::paymentId, $paymentId)
                ->where(VendorPayment::vendorId, $vendorId)
                ->first();

            return $vp ? (string) $vp->status : '0';
        };

        $getPaymentInfoValue = function ($coreKeyId) use ($vendorId) {
            if (! $vendorId) {
                return '';
            }
            $vpi = VendorPaymentInfo::select('value')
                ->where(VendorPaymentInfo::coreKeysId, $coreKeyId)
                ->where(VendorPaymentInfo::vendorId, $vendorId)
                ->first();

            return $vpi ? (string) $vpi->value : '';
        };

        return [
            'vendor_stripe_enabled' => $getPaymentStatus(Constants::stripePaymentId),
            'vendor_paypal_enabled' => $getPaymentStatus(Constants::paypalPaymentId),
            'vendor_razor_enabled' => $getPaymentStatus(Constants::razorPaymentId),
            'vendor_paystack_enabled' => $getPaymentStatus(Constants::paystackPaymentId),
            'vendor_cod_enabled' => $getPaymentStatus(Constants::codPaymentId),
            'vendor_flutterwave_enabled' => $getPaymentStatus(Constants::flutterwavePaymentId),
            'vendor_razor_key' => $getPaymentInfoValue(Constants::razorKey),
            'vendor_stripe_publishable_key' => $getPaymentInfoValue(Constants::stripePublishableKey),
            'vendor_paystack_key' => $getPaymentInfoValue(Constants::paystackKey),
            'vendor_flutterwave_public_key' => $getPaymentInfoValue(Constants::flutterwavePublicKey),
            'currency_id' => $currency_id,
            'vendor_delivery_setting' => $deliverySetting,
        ];
    }
}
