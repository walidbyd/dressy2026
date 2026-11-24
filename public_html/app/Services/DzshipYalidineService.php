<?php

namespace App\Services;

use Modules\StoreFront\VendorPanel\Entities\Order;

/**
 * Backward compatibility alias for YalidineService.
 * Replaced DZBuild entirely with direct Yalidine API v1 (https://api.yalidine.app/v1/).
 */
class DzshipYalidineService extends YalidineService
{
    public const COURIER_YALIDINE = 'yalidine';
    public const COURIER_SANDBOX = 'sandbox';

    public function normalizeDeliveryType(?string $deliveryType, $isStopDesk = null): string
    {
        return parent::normalizeDeliveryType($deliveryType, $isStopDesk);
    }

    public function normalizeWilayaCode($wilaya): int
    {
        return parent::normalizeWilayaCode($wilaya);
    }

    public function createShipment(Order $order): array
    {
        return parent::createShipment($order);
    }
}
