<?php

require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$p = \App\Models\Payment::find(39);
if (! $p) {
    exit("Payment 39 not found\n");
}

$token = config('services.bakong.token');
echo "Checking Payment 39 by Bill Number (Order ID): {$p->order_id}\n";

$response = \Illuminate\Support\Facades\Http::withToken($token)
    ->withOptions(['verify' => false])
    ->post('https://api-bakong.nbc.gov.kh/v1/check_transaction_by_bill_number', [
        'billNumber' => (string) $p->order_id,
        'accountId' => config('services.bakong.account_id'),
    ]);

echo 'Status: '.$response->status()."\n";
echo 'Body: '.$response->body()."\n";
