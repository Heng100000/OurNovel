<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

// Using the OLD token (iat Feb 25 2026) for diagnostic
$token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkYXRhIjp7ImlkIjoiZDg4MmE5ODE3OGY2NDk2NiJ9LCJpYXQiOjE3NzE3NzcyNzAsImV4cCI6MTc3OTU1MzI3MH0.HG40i3k47XBeqicfmbu-oMXgU-fHRcNkEnSh1LBIFhQ";
$accountId = "linh_sokheng@aclb";

echo "Testing with OLD Token...\n";

$response = \Illuminate\Support\Facades\Http::withToken($token)
    ->withOptions(['verify' => false])
    ->post('https://api-bakong.nbc.gov.kh/v1/check_transaction_by_md5', [
        'md5' => 'c53293c46a2f237646d9951302181792', // Example MD5 from logs
        'accountId' => $accountId
    ]);

echo "Status: " . $response->status() . "\n";
echo "Body: " . $response->body() . "\n";
