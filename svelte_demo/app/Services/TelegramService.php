<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class TelegramService
{
    protected string $token;

    public function __construct()
    {
        $this->token = config('services.telegram.bot_token') ?? '';
    }

    /**
     * Send a text message to a chat ID.
     */
    public function sendMessage(string|int $chatId, string $text): bool
    {
        return $this->callApi('sendMessage', [
            'chat_id' => $chatId,
            'text' => $text,
            'parse_mode' => 'Markdown',
        ]);
    }

    /**
     * Set the webhook URL for the bot.
     */
    public function setWebhook(string $url): bool
    {
        return $this->callApi('setWebhook', [
            'url' => $url,
        ]);
    }

    /**
     * Get current webhook info.
     */
    public function getWebhookInfo(): array
    {
        $response = Http::withOptions([
            'verify' => config('app.env') !== 'local',
        ])->get("https://api.telegram.org/bot{$this->token}/getWebhookInfo");

        return $response->json();
    }

    /**
     * Format an order invoice message for Telegram.
     */
    public function formatInvoiceMessage(\App\Models\Order $order): string
    {
        $order->load(['items.book', 'invoice']);
        $invoice = $order->invoice;

        if (!$invoice) {
            return "❌ Error: Invoice not found for Order #{$order->id}";
        }

        $itemsList = "";
        foreach ($order->items as $item) {
            $bookName = $item->book?->title ?? 'Unknown Product';
            $itemsList .= "• {$bookName} (x{$item->quantity}) - $" . number_format((float) $item->unit_price, 2) . "\n";
        }

        return "🛍️ *Order Invoice*\n\n" .
            "*Invoice No:* {$invoice->invoice_no}\n" .
            "--------------------------------\n" .
            "*Items:*\n{$itemsList}" .
            "--------------------------------\n" .
            "*Subtotal:* $" . number_format((float) $order->subtotal, 2) . "\n" .
            "*Shipping:* $" . number_format((float) $order->shipping_fee, 2) . "\n" .
            "*Grand Total:* $" . number_format((float) $order->total_price, 2) . "\n\n" .
            "Thank you for your purchase! 🇰🇭";
    }

    /**
     * Internal helper to call Telegram API.
     */
    protected function callApi(string $method, array $params): bool
    {
        if (empty($this->token)) {
            Log::error('Telegram Bot Token is not configured.');
            return false;
        }

        try {
            $response = Http::withOptions([
                'verify' => config('app.env') !== 'local',
            ])->post("https://api.telegram.org/bot{$this->token}/{$method}", $params);

            if ($response->successful()) {
                return true;
            }

            Log::error("Telegram {$method} failed", [
                'status' => $response->status(),
                'body' => $response->json(),
            ]);

            return false;
        } catch (\Exception $e) {
            Log::error("Telegram {$method} exception", [
                'message' => $e->getMessage(),
            ]);

            return false;
        }
    }
}
