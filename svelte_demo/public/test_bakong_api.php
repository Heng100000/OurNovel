<?php
require __DIR__.'/../vendor/autoload.php';
$app = require_once __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$token = config('services.bakong.token');
$md5 = '1380e83fb1f313ffdc163b31dcc1ee86d'; // Payment 56

echo "Testing Bakong MD5 Check for $md5 (NO Account ID)\n";

$response = \Illuminate\Support\Facades\Http::withToken($token)
    ->withOptions(['verify' => false])
    ->post('https://api-bakong.nbc.gov.kh/v1/check_transaction_by_md5', [
        'md5' => $md5,
    ]);

echo "Status: " . $response->status() . "\n";
echo "Body: " . $response->body() . "\n";
