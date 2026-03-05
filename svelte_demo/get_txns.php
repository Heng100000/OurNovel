<?php

require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$token = config('services.bakong.token');
echo 'Fetching Transaction List for Account: '.config('services.bakong.account_id')."\n";

$response = \Illuminate\Support\Facades\Http::withToken($token)
    ->withOptions(['verify' => false])
    ->post('https://api-bakong.nbc.gov.kh/v1/get_transaction_list', [
        'accountId' => config('services.bakong.account_id'),
    ]);

echo 'Status: '.$response->status()."\n";
echo 'Body: '.$response->body()."\n";
