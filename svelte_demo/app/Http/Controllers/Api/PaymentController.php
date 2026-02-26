<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\StorePaymentRequest;
use App\Http\Requests\Api\UpdatePaymentRequest;
use App\Http\Resources\Api\PaymentResource;
use App\Models\Order;
use App\Models\Payment;
use App\Services\BakongService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
    /**
     * List payments for the authenticated user's orders.
     */
    public function index(Request $request): AnonymousResourceCollection
    {
        Log::info('Payment API Index Hit', ['user_id' => $request->user()->id]);
        $query = Payment::query()->with('order');

        // If not admin, only show their own payments
        if ($request->user()->role !== 'admin') {
            $query->whereHas('order', fn ($q) => $q->where('user_id', $request->user()->id));
        }

        $payments = $query->latest()->get();

        return PaymentResource::collection($payments);
    }

    /**
     * Show a single payment.
     */
    public function show(Payment $payment): PaymentResource
    {
        Log::info('Payment API Show Hit', ['payment_id' => $payment->id]);
        // Gate::before in AppServiceProvider handles admin bypass
        $this->authorize('view', $payment);

        return new PaymentResource($payment->load('order'));
    }

    /**
     * Create a new payment for an order.
     */
    public function store(StorePaymentRequest $request, BakongService $bakongService): JsonResponse
    {
        Log::info('Payment API Store Hit', $request->all());
        $data = $request->validated();

        /** @var \App\Models\User $user */
        $user = $request->user();

        // If admin, allow paying for any order. Otherwise, only their own.
        $query = $user->role === 'admin' 
            ? Order::query() 
            : $user->orders();

        $order = $query->findOrFail($data['order_id']);

        $payment = Payment::create([
            'order_id' => $order->id,
            'method'   => $data['method'],
            'amount'   => $order->total_price,
            'status'   => 'pending',
        ]);

        // Auto-generate KHQR if method is supported
        if (in_array($payment->method, ['bakong', 'aba', 'aceleda'])) {
            $result = $bakongService->generateQR($payment);
            if ($result) {
                $payment->updateQuietly(['txn_id' => $result['md5']]);
                // Attach temporary property for Resource to use
                $payment->qr_image_url = $bakongService->getQrImageUrl($result['qr']);
            }
        }

        return (new PaymentResource($payment->load('order')))
            ->response()
            ->setStatusCode(201);
    }

    /**
     * Update a payment (e.g., method, amount, status, txn_id).
     * Only allowed when status is not 'paid'.
     */
    public function update(UpdatePaymentRequest $request, Payment $payment): PaymentResource|JsonResponse
    {
        $this->authorize('update', $payment);

        if ($payment->status === 'paid') {
            return response()->json(['message' => 'Cannot modify a completed payment.'], 422);
        }

        $payment->update($request->validated());

        return new PaymentResource($payment->load('order'));
    }

    /**
     * Check the Bakong transaction status by the stored MD5 (txn_id).
     * If paid, updates the payment status automatically.
     */
    public function checkKhqr(Payment $payment, BakongService $bakongService): JsonResponse
    {
        Log::info('Payment API Check KHQR Hit', ['payment_id' => $payment->id, 'status' => $payment->status]);

        if ($payment->status === 'paid') {
            return response()->json(['paid' => true, 'status' => 'paid']);
        }

        if (! $payment->txn_id) {
            return response()->json(['paid' => false, 'message' => 'No QR generated for this payment yet.'], 422);
        }

        Log::info('Bakong API polling', ['payment_id' => $payment->id]);

        $isPaid = $bakongService->checkTransactionByMD5($payment->txn_id);

        if ($isPaid) {
            $payment->update(['status' => 'paid']);

            // Also update the associated order status
            $payment->order()->update(['status' => 'paid']);

            return response()->json(['paid' => true, 'status' => 'paid']);
        }

        return response()->json(['paid' => false, 'status' => $payment->status]);
    }
}
