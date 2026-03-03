<?php
require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

$coupons = \App\Models\Coupon::whereRaw('LOWER(code) = ?', ['ahlong'])->get();
echo "Found " . $coupons->count() . " coupons with code 'ahlong':\n";
foreach ($coupons as $coupon) {
    echo "ID: {$coupon->id}, Active: {$coupon->is_active}, Valid From: {$coupon->valid_from}, Valid Until: {$coupon->valid_until}, Min Spend: {$coupon->min_spend}\n";
    
    // Check validation against 22.0
    echo "Validation test for 22.00: " . ($coupon->isValid(22.0) ? "PASS" : "FAIL") . "\n";
}
