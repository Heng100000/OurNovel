<?php

namespace App\Console\Commands;

use App\Services\TelegramService;
use Illuminate\Console\Command;

class TelegramSetWebhookCommand extends Command
{
    protected $signature = 'telegram:set-webhook {url?}';
    protected $description = 'Set the Telegram bot webhook URL';

    public function handle(TelegramService $telegramService)
    {
        $url = $this->argument('url') ?? config('app.url') . '/api/telegram/webhook';

        $this->info("Setting webhook to: {$url}");

        if ($telegramService->setWebhook($url)) {
            $this->info('✅ Webhook set successfully!');
        } else {
            $this->error('❌ Failed to set webhook. Check logs for details.');
        }
    }
}
