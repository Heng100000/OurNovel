<?php

namespace App\Observers;

use App\Models\CartItem;

class CartItemObserver
{
    /**
     * Handle the CartItem "created" event.
     */
    public function created(CartItem $cartItem): void
    {
        $cartItem->book()->decrement('stock_qty', $cartItem->quantity);
    }

    /**
     * Handle the CartItem "updated" event.
     */
    public function updated(CartItem $cartItem): void
    {
        if ($cartItem->isDirty('quantity')) {
            $diff = $cartItem->quantity - $cartItem->getOriginal('quantity');
            $cartItem->book()->decrement('stock_qty', $diff);
        }
    }

    /**
     * Handle the CartItem "deleted" event.
     */
    public function deleted(CartItem $cartItem): void
    {
        // If the cart is being cleared because an order was successfully paid,
        // DO NOT return the stock (it's already been reserved and converted to a permanent order).
        if (! \App\Models\CartItem::$isClearingAfterOrder) {
            $cartItem->book()->increment('stock_qty', $cartItem->quantity);
        }
    }
}
