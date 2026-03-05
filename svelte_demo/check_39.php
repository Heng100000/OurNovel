<?php

require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$p = \App\Models\Payment::find(39);
if (! $p) {
    exit("Payment 39 not found\n");
}

$bakong = app(\App\Services\BakongService::class);
echo "Checking Payment 39 (Amount: {$p->amount}, txn_id: {$p->txn_id})\n";
$isPaid = $bakong->checkTransactionByMD5($p->txn_id);
echo 'Result: '.($isPaid ? 'PAID' : 'NOT PAID')."\n";
