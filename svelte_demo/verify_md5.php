<?php

require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use KHQR\BakongKHQR;
use KHQR\Helpers\KHQRData;
use KHQR\Models\IndividualInfo;

$p = \App\Models\Payment::find(42);
if (! $p) {
    exit("Payment 42 not found\n");
}

echo "Checking Payment 42...\n";
echo 'Stored MD5: '.$p->txn_id."\n";

$info = new IndividualInfo(
    config('services.bakong.account_id'),
    config('services.bakong.merchant_name'),
    config('services.bakong.merchant_city'),
    null,
    null,
    KHQRData::CURRENCY_USD,
    (float) $p->amount,
    (string) $p->order_id
);

$response = BakongKHQR::generateIndividual($info);
$generatedMd5 = $response->data['md5'];

echo 'Generated MD5: '.$generatedMd5."\n";
echo 'Match: '.($p->txn_id === $generatedMd5 ? 'YES' : 'NO')."\n";
