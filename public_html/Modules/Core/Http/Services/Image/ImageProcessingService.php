<?php

namespace Modules\Core\Http\Services\Image;

use App\Http\Contracts\Configuration\BackendSettingServiceInterface;
use App\Http\Contracts\Image\ImageProcessingServiceInterface;
use App\Http\Contracts\Image\WaterMarkServiceInterface;
use App\Http\Services\PsService;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Storage;
use Intervention\Image\Facades\Image;
use Modules\Core\Constants\Constants;

/**
 * Note :
 *
 * Currently i am skipping the backend-water-mask-image preview logic.
 * This might case some problem in some places. may or may not.
 * Just the info that i am trying to remove all that preview logic code in all places.
 */
class ImageProcessingService extends PsService implements ImageProcessingServiceInterface
{
    private $storage_upload_path = '/storage/'.Constants::folderPath.'/uploads/';

    private $storage_thumb1x_path = '/storage/'.Constants::folderPath.'/thumbnail/';

    private $storage_thumb2x_path = '/storage/'.Constants::folderPath.'/thumbnail2x/';

    private $storage_thumb3x_path = '/storage/'.Constants::folderPath.'/thumbnail3x/';

    public function __construct(protected WaterMarkServiceInterface $waterMarkService) {}

    public function createImageFiles($file, $fileName, $imageType, array $resolutions = ['original'])
    {
        @ini_set('memory_limit', '256M');

        $images = [];
        foreach ($resolutions as $resolution) {
            $images[] = $this->createImageFile($file, $fileName, $imageType, $resolution);
        }

        return $images;
    }

    public function createImageFile($file, $fileName, $imageType, $resolution = 'original')
    {
        @ini_set('memory_limit', '256M');

        /**
         * @todo
         * Need to replace Backend Setting to get from Service Class
         */
        // To Get the Resize Image Sizes from Setting

        // can't use in constructor
        $backendSettingService = app()->make(BackendSettingServiceInterface::class);
        $backendSetting = $backendSettingService->get();

        // Create Image Obj

        $fileToProcess = clone $file;
        $image = Image::make($fileToProcess);

        // Check the storage folder
        $this->createDirectoryIfNotExists(public_path().$this->getStoragePath($resolution));

        // Resize Image according to resolution
        $resizedImage = $this->resizeImage($image, $backendSetting, $resolution);

        // Check Image Types to apply water mark
        if ($this->waterMarkService->isRequireWatermark($imageType)) {

            // Apply water mark
            // Water mark will only apply, if setting is ON
            $resizedImage = $this->waterMarkService->applyWatermark($resizedImage);
        }

        // Save final image at 82% quality (JPEG/WebP) to maintain crisp detail while reducing file size to 120-250KB
        $resizedImage->save(public_path().$this->getStoragePath($resolution).$fileName, 82);

        return $resizedImage;
    }

    /**
     * @coveredBy testCreateIcoFile*
     */
    public function createIcoFile($file, $fileName)
    {
        Storage::putFileAs($this->storage_upload_path, $file, $fileName);
        Storage::putFileAs($this->storage_thumb1x_path, $file, $fileName);
        Storage::putFileAs($this->storage_thumb2x_path, $file, $fileName);
        Storage::putFileAs($this->storage_thumb3x_path, $file, $fileName);
    }

    public function deleteImageFile($img_path)
    {
        Storage::delete($this->storage_upload_path.$img_path);
        Storage::delete($this->storage_thumb1x_path.$img_path);
        Storage::delete($this->storage_thumb2x_path.$img_path);
        Storage::delete($this->storage_thumb3x_path.$img_path);
    }

    // //////////////////////////////////////////////////////////////////
    // / Private Functions
    // //////////////////////////////////////////////////////////////////

    private function createDirectoryIfNotExists($path)
    {
        if (! File::isDirectory($path)) {
            File::makeDirectory($path, 0777, true, true);
        }
    }

    private function getStoragePath($resolution)
    {

        $paths = [
            '1x' => Constants::storageThumb1xPath,
            '2x' => Constants::storageThumb2xPath,
            '3x' => Constants::storageThumb3xPath,
            'original' => Constants::storageOriginalPath,
        ];

        return $paths[$resolution];

    }

    private function resizeImage($image, $backendSetting, $resolution)
    {
        $width = $image->width();
        $height = $image->height();
        $sizeConfig = $this->getSizeConfig($backendSetting, $resolution);

        if ($width > $height) {
            return $image->resize($sizeConfig['landscape'], null, function ($constraint) {
                $constraint->aspectRatio();
                $constraint->upsize();
            });
        } elseif ($width == $height) {
            return $image->resize($sizeConfig['square'], null, function ($constraint) {
                $constraint->aspectRatio();
                $constraint->upsize();
            });
        }

        return $image->resize(null, $sizeConfig['portrait'], function ($constraint) {
            $constraint->aspectRatio();
            $constraint->upsize();
        });
    }

    private function getSizeConfig($backendSetting, $resolution)
    {
        $configs = [
            '1x' => [
                'landscape' => (int)($backendSetting->landscape_thumb_width ?: 300),
                'square' => (int)($backendSetting->square_thumb_height ?: 300),
                'portrait' => (int)($backendSetting->potrait_thumb_height ?: 300),
            ],
            '2x' => [
                'landscape' => (int)($backendSetting->landscape_thumb2x_width ?: 600),
                'square' => (int)($backendSetting->square_thumb2x_height ?: 600),
                'portrait' => (int)($backendSetting->potrait_thumb2x_height ?: 600),
            ],
            '3x' => [
                'landscape' => (int)($backendSetting->landscape_thumb3x_width ?: 900),
                'square' => (int)($backendSetting->square_thumb3x_height ?: 900),
                'portrait' => (int)($backendSetting->potrait_thumb3x_height ?: 900),
            ],
            'original' => [
                'landscape' => !empty($backendSetting->landscape_width) ? min((int)$backendSetting->landscape_width, 1280) : 1280,
                'square' => !empty($backendSetting->square_height) ? min((int)$backendSetting->square_height, 1280) : 1280,
                'portrait' => !empty($backendSetting->potrait_height) ? min((int)$backendSetting->potrait_height, 1280) : 1280,
            ],
        ];

        return $configs[$resolution];
    }
}
