<?php
require __DIR__.'/../vendor/autoload.php';
$app = require_once __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\Payment;

$p = Payment::find(56);
if (!$p) {
    die("Payment 56 not found\n");
}

echo "Payment 56:\n";
echo "txn_id (DB): " . $p->txn_id . "\n";
echo "qr_code (DB): " . $p->qr_code . "\n";
echo "MD5 of qr_code: " . md5($p->qr_code) . "\n";

if ($p->txn_id === md5($p->qr_code)) {
    echo "CONSISTENCY: OK\n";
} else {
    echo "CONSISTENCY: FAILED (Mismatch!)\n";
}

echo "order_id: " . $p->order_id . "\n";
