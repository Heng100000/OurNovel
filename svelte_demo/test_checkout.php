<?php

require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$user = App\Models\User::first();
if (! $user) {
    exit("No user found\n");
}

// Add a test cart item
$user->cartItems()->create([
    'book_id' => 1,
    'quantity' => 1,
    'unit_price' => 10,
]);

echo 'Cart items before checkKhqr: '.$user->cartItems()->count()."\n";

$payment = App\Models\Payment::find(9);
// reset for test
$payment->update(['status' => 'pending']);
$payment->order->update(['status' => 'pending']);
$payment->order->update(['user_id' => $user->id]); // associate with our test user

echo "Checking KHQR...\n";
$controller = app(App\Http\Controllers\Api\PaymentController::class);
$bakongService = app(App\Services\BakongService::class);
$response = $controller->checkKhqr($payment, $bakongService);

echo $response->getContent()."\n";
echo 'Cart items after checkKhqr: '.$user->cartItems()->count()."\n";
echo 'Order status: '.$payment->order->fresh()->status."\n";
echo "Done.\n";
