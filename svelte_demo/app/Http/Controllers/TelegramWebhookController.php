<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class TelegramWebhookController extends Controller
{
    /**
     * Handle incoming Telegram webhook updates.
     */
    public function handle(Request $request)
    {
        Log::info('Telegram Webhook update received', $request->all());
        $update = $request->all();

        if (!isset($update['message'])) {
            return response()->json(['status' => 'ok']);
        }

        $message = $update['message'];
        $chatId = $message['chat']['id'] ?? null;
        $text = $message['text'] ?? '';

        // Check for /start [parameter]
        if (str_starts_with($text, '/start')) {
            $parts = explode(' ', $text);
            
            if (count($parts) > 1) {
                $userId = $parts[1];
                
                // For security, we should ideally use an encrypted or hashed ID
                // But for simplicity in this demo, we'll use the plain ID
                $user = User::find($userId);

                if ($user) {
                    $user->update(['telegram_chat_id' => $chatId]);

                    Log::info("Telegram Chat ID linked for user: {$user->id}");

                    // Optional: Send a confirmation message back
                    app(\App\Services\TelegramService::class)->sendMessage(
                        $chatId, 
                        "✅ *Account Linked!*\n\nHello {$user->name}, your account is now linked to receive invoices via Telegram."
                    );
                }
            } else {
                // Sent plain /start without user ID
                app(\App\Services\TelegramService::class)->sendMessage(
                    $chatId, 
                    "👋 *Hello!*\n\nTo link your account, please use the specific link provided in your dashboard."
                );
            }
        }

        return response()->json(['status' => 'ok']);
    }
}
