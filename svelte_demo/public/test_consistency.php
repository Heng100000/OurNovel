<?php
require __DIR__.'/../vendor/autoload.php';
$app = require_once __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Services\BakongService;
use App\Models\Payment;

$bakong = new BakongService();
$payment = new Payment([
    'amount' => 0.01,
    'order_id' => 'TEST'.time(),
    'method' => 'bakong'
]);

echo "Generating test QR for $0.01...\n";
$result = $bakong->generateQR($payment);

if (!$result) {
    echo "FAILED to generate QR\n";
    exit;
}

$md5 = $result['md5'];
echo "Generated MD5: $md5\n";
echo "QR String: " . $result['qr'] . "\n";

echo "Checking status for $md5...\n";
$statusResult = $bakong->checkTransactionByMD5($md5);

echo "Check Result: " . json_encode($statusResult) . "\n";
