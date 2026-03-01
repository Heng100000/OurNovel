<?php

namespace App\Observers;

use App\Models\Order;

class OrderObserver
{
    /**
     * Handle the Order "created" event.
     */
    public function created(Order $order): void
    {
        $order->invoice()->create([
            'invoice_no' => 'INV-'.now()->format('Ymd').'-'.str_pad($order->id, 5, '0', STR_PAD_LEFT),
            'sub_total' => $order->subtotal,
            'shipping_fee' => $order->shipping_fee,
            'tax_amount' => 0,
            'grand_total' => $order->total_price,
        ]);

        if ($order->delivery_method === 'delivery' && $order->delivery_company_id) {
            $order->shipping()->create([
                'delivery_company_id' => $order->delivery_company_id,
                'status' => 'pending',
            ]);
        }

        // Cart items are no longer cleared here; they are cleared upon successful payment.

        // automatically send Telegram Invoice ONLY if paid immediately
        if ($order->status === 'paid') {
            $this->sendTelegramInvoice($order);
        }
    }

    /**
     * Send automatic Telegram notification with invoice details.
     */
    protected function sendTelegramInvoice(Order $order): void
    {
        $user = $order->user;

        if (! $user || ! $user->telegram_chat_id) {
            return;
        }

        $telegramService = app(\App\Services\TelegramService::class);
        $message = $telegramService->formatInvoiceMessage($order);

        \Log::info("TelegramObserver: Sending invoice for Order #{$order->id} to Chat ID: {$user->telegram_chat_id}");
        $telegramService->sendMessage($user->telegram_chat_id, $message);
    }

    /**
     * Handle the Order "updated" event.
     */
    public function updated(Order $order): void
    {
        // Update invoice if financial fields change
        if ($order->isDirty(['subtotal', 'shipping_fee', 'total_price'])) {
            $order->invoice()->update([
                'sub_total' => $order->subtotal,
                'shipping_fee' => $order->shipping_fee,
                'grand_total' => $order->total_price,
            ]);
        }

        // Update shipping if delivery company changes
        if ($order->isDirty('delivery_company_id')) {
            if ($order->shipping) {
                $order->shipping()->update([
                    'delivery_company_id' => $order->delivery_company_id,
                ]);
            } elseif ($order->delivery_method === 'delivery' && $order->delivery_company_id) {
                // If shipping record doesn't exist but method is delivery (e.g., changed from pickup)
                $order->shipping()->create([
                    'delivery_company_id' => $order->delivery_company_id,
                    'status' => 'pending',
                ]);
            }
        }

        // Send Telegram Invoice when status changes to 'paid'
        if ($order->wasChanged('status') && strtolower($order->status) === 'paid') {
            \Log::info("TelegramObserver: Order #{$order->id} status changed to paid, triggering notification.");
            $this->sendTelegramInvoice($order);
        }
    }

    /**
     * Handle the Order "deleted" event.
     */
    public function deleted(Order $order): void
    {
        //
    }

    /**
     * Handle the Order "restored" event.
     */
    public function restored(Order $order): void
    {
        //
    }

    /**
     * Handle the Order "force deleted" event.
     */
    public function forceDeleted(Order $order): void
    {
        //
    }
}
