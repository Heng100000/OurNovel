<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Coupon;
use App\Http\Requests\StoreCouponRequest;
use App\Http\Requests\UpdateCouponRequest;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class CouponController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        //
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(StoreCouponRequest $request)
    {
        //
    }

    /**
     * Display the specified resource.
     */
    public function show(Coupon $coupon)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Coupon $coupon)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(UpdateCouponRequest $request, Coupon $coupon)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(Coupon $coupon)
    {
        //
    }

    /**
     * Apply a coupon based on the provided code and subtotal.
     */
    public function apply(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'code' => 'required|string',
            'subtotal' => 'required|numeric|min:0',
        ]);

        // Make sure the incoming code is converted to uppercase since we know the coupon is 'AHLONG'.
        // Or fetch generically case-insensitive:
        $coupon = Coupon::whereRaw('LOWER(code) = ?', [strtolower($validated['code'])])->first();

        // Debugging
        file_put_contents(storage_path('logs/diag.txt'), "Applying coupon {$validated['code']} with SUBTOTAL: {$validated['subtotal']} at " . now() . "\n", FILE_APPEND);
        \Illuminate\Support\Facades\Log::emergency("Applying coupon {$validated['code']} with SUBTOTAL: {$validated['subtotal']}");

        if (!$coupon) {
            return response()->json(['message' => 'Invalid coupon code.'], 404);
        }

        if (!$coupon->isValid((float)$validated['subtotal'])) {
            return response()->json(['message' => 'This coupon is not valid for your order.'], 400);
        }

        $discount = $coupon->calculateDiscount((float)$validated['subtotal']);

        return response()->json([
            'coupon_id' => $coupon->id,
            'code' => $coupon->code,
            'type' => $coupon->type,
            'amount' => $coupon->amount,
            'discount_amount' => $discount,
        ]);
    }
}
