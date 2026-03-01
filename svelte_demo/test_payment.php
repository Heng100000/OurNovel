<?php

require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$payment = App\Models\Payment::find(9);
if (! $payment) {
    exit("Payment 9 not found\n");
}

// reset for test
$payment->update(['status' => 'pending']);
$payment->order->update(['status' => 'pending']);

echo "Checking KHQR for payment {$payment->id}...\n";
$controller = app(App\Http\Controllers\Api\PaymentController::class);
$bakongService = app(App\Services\BakongService::class);
$response = $controller->checkKhqr($payment, $bakongService);

echo $response->getContent();
echo "\nDone.\n";
