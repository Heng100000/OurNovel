<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\CartItemResource;
use App\Models\CartItem;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class CartItemController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $items = $request->user()->cartItems()->with('book.primaryImage')->get();

        return CartItemResource::collection($items);
    }

    public function store(Request $request): CartItemResource|JsonResponse
    {
        $request->validate([
            'book_id' => 'required|exists:books,id',
            'quantity' => 'required|integer|min:1',
        ]);

        $book = \App\Models\Book::findOrFail($request->book_id);
        $cartItem = $request->user()->cartItems()->where('book_id', $request->book_id)->first();

        $newQuantity = $request->quantity;
        if ($cartItem) {
            $newQuantity += $cartItem->quantity;
        }

        if ($newQuantity > $book->stock_qty) {
            return response()->json([
                'message' => 'Cannot add more items than available in stock.',
                'available_stock' => $book->stock_qty,
            ], 422);
        }

        if ($cartItem) {
            $cartItem->quantity = $newQuantity;
            $cartItem->save();
        } else {
            $unitPrice = $book->discounted_price ?? $book->price;
            $cartItem = $request->user()->cartItems()->create([
                'book_id' => $request->book_id,
                'quantity' => $request->quantity,
                'unit_price' => $unitPrice,
            ]);
        }

        return new CartItemResource($cartItem->load('book.primaryImage'));
    }

    public function update(Request $request, CartItem $cart): CartItemResource|JsonResponse
    {
        $this->authorize('update', $cart);

        $request->validate([
            'quantity' => 'required|integer|min:1',
        ]);

        $book = $cart->book;
        if ($request->quantity > $book->stock_qty) {
            return response()->json([
                'message' => 'Requested quantity exceeds available stock.',
                'available_stock' => $book->stock_qty,
            ], 422);
        }

        $cart->update(['quantity' => $request->quantity]);

        return new CartItemResource($cart->load('book.primaryImage'));
    }

    public function destroy(CartItem $cart): JsonResponse
    {
        $this->authorize('delete', $cart);
        $cart->delete();

        return response()->json(null, 204);
    }
}
