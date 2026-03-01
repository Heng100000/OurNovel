<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class OrderController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $orders = $request->user()->orders()->with(['items.book', 'shipping'])->latest()->get();

        return response()->json($orders);
    }

    public function show(Order $order): JsonResponse
    {
        $this->authorize('view', $order);
        $order->load(['items.book', 'shipping', 'invoice', 'payment']);

        return response()->json($order);
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'delivery_method' => 'required|in:delivery,pickup',
            'address_id' => 'required_if:delivery_method,delivery|nullable|exists:user_addresses,id',
            'delivery_company_id' => 'required_if:delivery_method,delivery|nullable|exists:delivery_companies,id',
            'status' => 'nullable|string',
        ]);

        $user = $request->user();
        $cartItems = $user->cartItems()->with('book')->get();

        if ($cartItems->isEmpty()) {
            return response()->json(['message' => 'Your cart is empty'], 422);
        }

        $shippingFee = 0;
        if ($request->delivery_method === 'delivery') {
            // Get the shipping rate fee (dependent only on delivery company)
            $shippingRate = \App\Models\ShippingRate::where('delivery_company_id', $request->delivery_company_id)
                ->first();

            $shippingFee = $shippingRate?->fee ?? 0;
        }

        // Check for stock availability
        foreach ($cartItems as $item) {
            $book = $item->book;
            if ($book->stock_qty < $item->quantity) {
                $isLowStock = $book->stock_qty < $book->warning_qty;
                $messagePrefix = $isLowStock ? 'Critical stock levels! ' : 'Insufficient stock! ';

                return response()->json([
                    'message' => "{$messagePrefix}Only {$book->stock_qty} available for '{$book->title}'.",
                    'error' => 'out_of_stock',
                ], 422);
            }
        }

        $startTime = microtime(true);
        try {
            return DB::transaction(function () use ($request, $user, $cartItems, $shippingFee, $startTime) {
                Log::info('OrderStore: Transaction started', ['elapsed' => microtime(true) - $startTime]);
                $subtotal = $cartItems->reduce(function ($carry, $item) {
                    $price = $item->book->discounted_price ?? $item->book->price ?? 0;

                    return $carry + ($item->quantity * $price);
                }, 0);

                $order = Order::create([
                    'user_id' => $user->id,
                    'delivery_method' => $request->delivery_method,
                    'address_id' => $request->delivery_method === 'delivery' ? $request->address_id : null,
                    'delivery_company_id' => $request->delivery_method === 'delivery' ? $request->delivery_company_id : null,
                    'status' => $request->status ?? 'Pending',
                    'subtotal' => $subtotal,
                    'shipping_fee' => $shippingFee,
                    'total_price' => $subtotal + $shippingFee,
                ]);

                $orderItemsData = $cartItems->map(function ($item) {
                    return [
                        'book_id' => $item->book_id,
                        'quantity' => $item->quantity,
                        'unit_price' => $item->book->discounted_price ?? $item->book->price ?? 0,
                    ];
                })->toArray();

                $order->items()->createMany($orderItemsData);

                // We no longer clear the cart here.
                // The cart should only be cleared upon SUCCESSFUL payment via PaymentController.

                // Notify Admin via Email (Existing)
                Log::info('OrderStore: Preparing email', ['elapsed' => microtime(true) - $startTime]);
                try {
                    \Illuminate\Support\Facades\Mail::to('admin@bookstore.com')->send(new \App\Mail\Admin\NewOrderNotification($order));
                } catch (\Exception $e) {
                    \Illuminate\Support\Facades\Log::error('Failed to send admin order email notification: '.$e->getMessage());
                }

                // Notify Admin via Filament Notification (New)
                Log::info('OrderStore: Preparing Filament notification', ['elapsed' => microtime(true) - $startTime]);
                try {
                    $admins = \App\Models\User::where('role', 'admin')->orWhere('id', 1)->get();

                    \Filament\Notifications\Notification::make()
                        ->title('New Order Received')
                        ->icon('heroicon-o-shopping-cart')
                        ->body("Order #{$order->id} has been placed by {$user->name}.")
                        ->actions([
                            \Filament\Actions\Action::make('view')
                                ->url(\App\Filament\Resources\Orders\OrderResource::getUrl('edit', ['record' => $order]))
                                ->button(),
                        ])
                        ->sendToDatabase($admins);
                    Log::info('OrderStore: Filament notification sent', ['elapsed' => microtime(true) - $startTime]);
                } catch (\Exception $e) {
                    \Illuminate\Support\Facades\Log::error('Failed to send admin Filament notification: '.$e->getMessage());
                }

                Log::info('OrderStore: Completing request', ['elapsed' => microtime(true) - $startTime]);

                return response()->json($order->load(['items', 'deliveryCompany']), 201);
            });
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error('Order creation failed: '.$e->getMessage(), [
                'trace' => $e->getTraceAsString(),
                'request' => $request->all(),
            ]);

            return response()->json(['message' => 'Order creation failed', 'error' => $e->getMessage()], 500);
        }
    }

    public function sendTelegramInvoice(Order $order, \App\Services\TelegramService $telegramService): JsonResponse
    {
        $this->authorize('view', $order);

        $user = $order->user;

        if (! $user->telegram_chat_id) {
            return response()->json([
                'message' => 'User has not linked their Telegram account.',
            ], 422);
        }

        $message = $telegramService->formatInvoiceMessage($order);
        $success = $telegramService->sendMessage($user->telegram_chat_id, $message);

        if ($success) {
            return response()->json(['message' => 'Invoice sent to Telegram successfully.']);
        }

        return response()->json(['message' => 'Failed to send invoice to Telegram.'], 500);
    }
}
