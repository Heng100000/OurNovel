<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ShippingRateResource;
use App\Models\ShippingRate;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class ShippingRateController extends Controller
{
    /**
     * Display a listing of shipping rates.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        $query = ShippingRate::query()->with('deliveryCompany');

        if ($request->has('delivery_company_id')) {
            $query->where('delivery_company_id', $request->delivery_company_id);
        }

        return ShippingRateResource::collection($query->get());
    }
}
