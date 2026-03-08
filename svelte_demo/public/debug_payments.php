<?php
require __DIR__.'/../vendor/autoload.php';
$app = require_once __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\Payment;

$md5 = 'c89943692ff73e41ac4af67fccd40fbb';
$p = Payment::where('txn_id', $md5)->first();

if ($p) {
    echo "Found Payment ID: " . $p->id . "\n";
} else {
    echo "Payment $md5 NOT FOUND in DB\n";
}
