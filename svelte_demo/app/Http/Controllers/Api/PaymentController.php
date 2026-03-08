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
    public function show(Payment $payment, BakongService $bakongService): PaymentResource
    {
        Log::info('Payment API Show Hit', ['payment_id' => $payment->id]);
        // Gate::before in AppServiceProvider handles admin bypass
        $this->authorize('view', $payment);

        // Ensure QR data is available even for existing payments
        if (in_array($payment->method, ['bakong', 'aba', 'aceleda']) && $payment->status === 'pending') {
            $result = $bakongService->generateQR($payment);
            if ($result) {
                // We update the txn_id in case config changed, but be careful with existing payments.
                // However, the current check logic uses txn_id from DB.
                // If we want to support checking by MD5, we must match what's on the user's screen.
                $payment->updateQuietly(['txn_id' => $result['md5']]);
                $payment->qr_code = $result['qr'];
                $payment->qr_image_url = $bakongService->getQrImageUrl($result['qr']);
                $payment->deep_link = $bakongService->generateDeepLink($result['qr']);
            }
        }

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

        $startTime = microtime(true);
        $payment = Payment::create([
            'order_id' => $order->id,
            'method' => $data['method'],
            'amount' => $order->total_price,
            'status' => 'pending',
        ]);

        // Auto-generate KHQR if method is supported
        if (in_array($payment->method, ['bakong', 'aba', 'aceleda'])) {
            Log::info('PaymentStore: Generating Bakong QR', ['elapsed' => microtime(true) - $startTime]);
            $result = $bakongService->generateQR($payment);
            Log::info('PaymentStore: Bakong QR generated', ['elapsed' => microtime(true) - $startTime]);
            if ($result) {
                $payment->updateQuietly(['txn_id' => $result['md5']]);
                // Attach temporary properties for Resource to use
                $payment->qr_code = $result['qr'];
                $payment->qr_image_url = $bakongService->getQrImageUrl($result['qr']);
                $payment->deep_link = $bakongService->generateDeepLink($result['qr']);
            }
        } elseif ($payment->method === 'cash') {
            Log::info('PaymentStore: Handling Cash Payment', ['elapsed' => microtime(true) - $startTime]);
            // Cash payments are immediately successful in the app flow.
            $payment->update(['status' => 'paid']);
            $order->update(['status' => 'paid']);

            // Clear the cart - set flag to prevent stock return
            \App\Models\CartItem::$isClearingAfterOrder = true;
            $user->cartItems()->delete();
            \App\Models\CartItem::$isClearingAfterOrder = false;
        }

        Log::info('PaymentStore: Completing request', ['elapsed' => microtime(true) - $startTime]);

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

        Log::info('Bakong API polling', ['payment_id' => $payment->id, 'md5' => $payment->txn_id, 'bill' => $payment->order_id]);

        $checkResult = $bakongService->checkTransactionByMD5($payment->txn_id);
        $isPaid = $checkResult['success'];
        $bakongMsg = $checkResult['message'];

        if (! $isPaid) {
            Log::info('MD5 check failed, trying Bill Number fallback', ['payment_id' => $payment->id, 'reason' => $bakongMsg]);
            $checkResult = $bakongService->checkTransactionByBillNumber((string) $payment->order_id);
            $isPaid = $checkResult['success'];
            $bakongMsg = $checkResult['message'];
        }

        Log::info('checkKhqr result', [
            'payment_id' => $payment->id, 
            'isPaid' => $isPaid, 
            'order_id' => $payment->order_id,
            'bakong_msg' => $bakongMsg
        ]);

        if ($isPaid) {
            Log::info('Updating payment and order to paid', ['payment_id' => $payment->id, 'order_id' => $payment->order_id]);
            $payment->update(['status' => 'paid']);

            // Get the order instance and update it to trigger observers (e.g., TelegramInvoice)
            $order = clone $payment->order;
            $order->update(['status' => 'paid']);

            Log::info('Clearing user cart', ['user_id' => $order->user_id]);
            \App\Models\CartItem::$isClearingAfterOrder = true;
            $order->user->cartItems()->delete();
            \App\Models\CartItem::$isClearingAfterOrder = false;
            Log::info('Cart cleared successfully');

            return response()->json(['paid' => true, 'status' => 'paid']);
        }

        return response()->json([
            'paid' => false, 
            'status' => $payment->status,
            'bakong_msg' => $bakongMsg,
            'bakong_debug' => $bakongService->getDebugInfo()
        ]);
    }
}
