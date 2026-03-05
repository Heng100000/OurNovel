<?php

require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$payments = \App\Models\Payment::latest()->take(20)->get();
echo "ID | Amount | Status | Method | Created At\n";
echo "---|--------|--------|--------|-----------\n";
foreach ($payments as $p) {
    echo "{$p->id} | {$p->amount} | {$p->status} | {$p->method} | {$p->created_at}\n";
}
