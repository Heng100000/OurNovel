<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\BannerResource;
use App\Models\Banner;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class BannerController extends Controller
{
    /**
     * Display a listing of the banners.
     */
    public function index(): AnonymousResourceCollection
    {
        $banners = Banner::where('status', 'active')
            ->orderBy('display_order')
            ->get();

        return BannerResource::collection($banners);
    }

    /**
     * Display the specified banner.
     */
    public function show(Banner $banner): BannerResource
    {
        return new BannerResource($banner);
    }
}
