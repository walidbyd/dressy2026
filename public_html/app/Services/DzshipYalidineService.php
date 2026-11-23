<?php

namespace App\Services;

/**
 * Backward compatibility alias for YalidineService.
 * Replaced DZBuild entirely with direct Yalidine API v1 (https://api.yalidine.app/v1/).
 */
class DzshipYalidineService extends YalidineService
{
    public const COURIER_YALIDINE = 'yalidine';
    public const COURIER_SANDBOX = 'sandbox';
}
