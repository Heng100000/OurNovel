<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Book;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

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
            'address_id' => 'required|exists:user_addresses,id',
            'delivery_company_id' => 'required|exists:delivery_companies,id',
            'status' => 'nullable|string',
        ]);

        $user = $request->user();
        $cartItems = $user->cartItems()->with('book')->get();

        if ($cartItems->isEmpty()) {
            return response()->json(['message' => 'Your cart is empty'], 422);
        }

        // Get the shipping rate fee (dependent only on delivery company)
        $shippingRate = \App\Models\ShippingRate::where('delivery_company_id', $request->delivery_company_id)
            ->first();

        $shippingFee = $shippingRate?->fee ?? 0;

        // Check for stock availability
        foreach ($cartItems as $item) {
            $book = $item->book;
            if ($book->stock_qty < $item->quantity) {
                $isLowStock = $book->stock_qty < $book->warning_qty;
                $messagePrefix = $isLowStock ? "Critical stock levels! " : "Insufficient stock! ";
                
                return response()->json([
                    'message' => "{$messagePrefix}Only {$book->stock_qty} available for '{$book->title}'.",
                    'error' => 'out_of_stock'
                ], 422);
            }
        }

        try {
            return DB::transaction(function () use ($request, $user, $cartItems, $shippingFee) {
                $subtotal = $cartItems->reduce(function ($carry, $item) {
                    $price = $item->book->discounted_price ?? $item->book->price ?? 0;
                    return $carry + ($item->quantity * $price);
                }, 0);

                $order = Order::create([
                    'user_id' => $user->id,
                    'address_id' => $request->address_id,
                    'delivery_company_id' => $request->delivery_company_id,
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

                // Clear the cart
                $user->cartItems()->delete();

                // Notify Admin via Email (Existing)
                try {
                    \Illuminate\Support\Facades\Mail::to('admin@bookstore.com')->send(new \App\Mail\Admin\NewOrderNotification($order));
                } catch (\Exception $e) {
                    \Illuminate\Support\Facades\Log::error('Failed to send admin order email notification: ' . $e->getMessage());
                }

                // Notify Admin via Filament Notification (New)
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
                } catch (\Exception $e) {
                    \Illuminate\Support\Facades\Log::error('Failed to send admin Filament notification: ' . $e->getMessage());
                }

                return response()->json($order->load(['items', 'deliveryCompany']), 201);
            });
        } catch (\Exception $e) {
            return response()->json(['message' => 'Order creation failed', 'error' => $e->getMessage()], 500);
        }
    }

    public function sendTelegramInvoice(Order $order, \App\Services\TelegramService $telegramService): JsonResponse
    {
        $this->authorize('view', $order);

        $user = $order->user;

        if (!$user->telegram_chat_id) {
            return response()->json([
                'message' => 'User has not linked their Telegram account.'
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
