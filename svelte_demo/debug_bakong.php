<?php

require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$p = \App\Models\Payment::latest()->first();
if (! $p) {
    exit("No payments found.\n");
}

echo "--- Payment Details ---\n";
echo 'ID: '.$p->id."\n";
echo 'Status: '.$p->status."\n";
echo 'txn_id (MD5): '.$p->txn_id."\n";
echo 'Amount: '.$p->amount."\n";
echo 'Order ID: '.$p->order_id."\n";

$token = config('services.bakong.token');

echo "\n--- Checking WITH Token ---\n";
$response = \Illuminate\Support\Facades\Http::withToken($token)
    ->withOptions(['verify' => false])
    ->post('https://api-bakong.nbc.gov.kh/v1/check_transaction_by_md5', [
        'md5' => $p->txn_id,
    ]);
echo 'Status: '.$response->status()."\n";
echo 'Body: '.$response->body()."\n";

echo "\n--- Checking WITHOUT Token ---\n";
$response = \Illuminate\Support\Facades\Http::withOptions(['verify' => false])
    ->post('https://api-bakong.nbc.gov.kh/v1/check_transaction_by_md5', [
        'md5' => $p->txn_id,
    ]);
echo 'Status: '.$response->status()."\n";
echo 'Body: '.$response->body()."\n";
