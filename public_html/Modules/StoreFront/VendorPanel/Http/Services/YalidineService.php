<?php

namespace Modules\StoreFront\VendorPanel\Http\Services;

use App\Services\YalidineService as BaseYalidineService;

/**
 * VendorPanel wrapper for YalidineService to ensure compatibility.
 */
class YalidineService extends BaseYalidineService
{
    // Inherits all methods, credentials resolution, caching, and parcel creation logic
}
