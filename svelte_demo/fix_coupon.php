<?php
require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

$coupon = \App\Models\Coupon::whereRaw('LOWER(code) = ?', ['ahlong'])->first();
if ($coupon) {
    $coupon->valid_from = null;
    $coupon->valid_until = null;
    $coupon->is_active = true;
    $coupon->save();
    echo "Coupon Ahlong updated successfully.\n";
    
    // Test validation
    $now = now();
    $isValid = $coupon->isValid(22.0);
    echo "Validation test for subtotal 22.0 at {$now}: " . ($isValid ? "PASS" : "FAIL") . "\n";
} else {
    echo "Coupon not found.\n";
}
