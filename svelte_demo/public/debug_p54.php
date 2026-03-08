<?php
require __DIR__.'/../vendor/autoload.php';
$app = require_once __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\Payment;

$p = Payment::find(54);
if ($p) {
    echo "ID: " . $p->id . "\n";
    echo "Method: " . $p->method . "\n";
    echo "Status: " . $p->status . "\n";
    echo "txn_id: [" . ($p->txn_id ?? 'NULL') . "]\n";
} else {
    echo "Payment 54 not found\n";
}
