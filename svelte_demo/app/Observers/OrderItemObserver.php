<?php

namespace App\Observers;

use App\Models\OrderItem;

class OrderItemObserver
{
    /**
     * Handle the OrderItem "created" event.
     */
    public function created(OrderItem $orderItem): void
    {
        // Stock is now reserved at the CART stage (CartItemObserver).
        // When an OrderItem is created, it inherits that reservation.
        // We only decrement here if it's NOT coming from a cart (e.g. Manual Admin Order).
        if (! request()->has('from_cart') && ! request()->is('api/orders*')) {
            $orderItem->book()->decrement('stock_qty', $orderItem->quantity);
        }
    }

    /**
     * Handle the OrderItem "deleted" event.
     */
    public function deleted(OrderItem $orderItem): void
    {
        $orderItem->book()->increment('stock_qty', $orderItem->quantity);
    }

    /**
     * Handle the OrderItem "restored" event.
     */
    public function restored(OrderItem $orderItem): void
    {
        //
    }

    /**
     * Handle the OrderItem "force deleted" event.
     */
    public function forceDeleted(OrderItem $orderItem): void
    {
        //
    }
}
