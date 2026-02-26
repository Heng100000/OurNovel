<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DeliveryCompany;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class DeliveryCompanyController extends Controller
{
    public function index(): JsonResponse
    {
        $companies = DeliveryCompany::where('is_active', true)->with('shippingRates')->get();
        return response()->json($companies);
    }

    public function show(DeliveryCompany $delivery_company): JsonResponse
    {
        $delivery_company->load('shippingRates');
        return response()->json($delivery_company);
    }
}
