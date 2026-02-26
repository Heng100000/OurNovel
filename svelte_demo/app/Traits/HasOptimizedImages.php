<?php

namespace App\Traits;

use Illuminate\Support\Facades\Storage;

trait HasOptimizedImages
{
    /**
     * Get an optimized Supabase image URL or a standard URL if not available.
     *
     * @param string|null $path The relative path to the image
     * @param int|null $width
     * @param int|null $height
     * @param int $quality
     * @param string $format
     * @return string|null
     */
    public function getOptimizedImageUrl(?string $path, ?int $width = null, ?int $height = null, int $quality = 70, string $format = 'origin'): ?string
    {
        if (!$path) {
            return null;
        }

        $disk = Storage::disk('supabase');
        
        // If config is missing or not using S3 driver, return standard public URL
        if (config('filesystems.disks.supabase.driver') !== 's3' || !config('filesystems.disks.supabase.url')) {
            return $disk->url($path);
        }

        $supabaseUrl = config('filesystems.disks.supabase.url');
        $bucket = config('filesystems.disks.supabase.bucket');
        
        // Extract base project URL (e.g., https://xyz.supabase.co)
        $baseUrl = parse_url($supabaseUrl, PHP_URL_SCHEME) . '://' . parse_url($supabaseUrl, PHP_URL_HOST);

        $params = [];
        if ($width) $params['width'] = $width;
        if ($height) $params['height'] = $height;
        $params['quality'] = $quality;
        $params['format'] = $format;

        // Render URL for optimized delivery
        return "{$baseUrl}/storage/v1/render/image/public/{$bucket}/{$path}?" . http_build_query($params);
    }
}
