<?php

namespace Modules\Installer\Helpers;

use Exception;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Log;
use Modules\Core\Entities\Installer;

class InstalledFileManager
{
    /**
     * Create installed file.
     *
     * @return int
     */
    public function create()
    {
        $installedLogFile = storage_path('installed');
        $message = config('app.base_domain');

        try {
            File::put($installedLogFile, $message);
        } catch (Exception $e) {
            Log::error($e->getMessage());
        }

        $installer = Installer::first();
        if (! empty($installer)) {
            $installer->is_installed = 1;
            $installer->update();
        } else {
            $installerNew = new Installer;
            $installerNew->is_installed = 1;
            $installerNew->save();
        }

    }

    /**
     * Update installed file.
     *
     * @return int
     */
    public function update()
    {
        return $this->create();
    }

    public function isInstalled()
    {
        try {
            $installer = Installer::first();
            if ($installer && $installer->is_installed == 1) {
                return true;
            }
        } catch (\Throwable $e) {
            // Table might not exist yet during fresh install
        }

        $installedLogFile = storage_path('installed');

        if (! file_exists($installedLogFile)) {
            return false;
        }

        return true;
    }

    public function storeOwner($email)
    {
        $licenseOwnerFile = storage_path('license_owner');

        try {
            File::put($licenseOwnerFile, $email);
        } catch (Exception $e) {
            Log::error($e->getMessage());
        }
    }

    public function getOwner()
    {
        $licenseOwnerFile = storage_path('license_owner');

        if (! file_exists($licenseOwnerFile)) {
            return '';
        }

        return file_get_contents($licenseOwnerFile);
    }

    public function isDevMode($request)
    {
        $host = $request->getHost();
        $ip = $request->ip();

        return $host === 'localhost'
            || $ip === '127.0.0.1'
            || $ip === '::1'
            || $host === '10.0.2.2'
            || str_starts_with($ip, '192.168.')
            || str_starts_with($host, '192.168.')
            || str_starts_with($ip, '10.')
            || str_starts_with($host, '10.');
    }
}
