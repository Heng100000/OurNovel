<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$book = \App\Models\Book::with('promotion')->find(3);

echo "NOW: " . now() . "\n";
if ($book->promotion) {
    echo "PROMO_START: " . $book->promotion->start_date . "\n";
    echo "PROMO_START_DAY: " . $book->promotion->start_date->startOfDay() . "\n";
    echo "PROMO_END: " . $book->promotion->end_date . "\n";
    echo "PROMO_END_DAY: " . $book->promotion->end_date->endOfDay() . "\n";
    echo "GT_START: " . (now()->gte($book->promotion->start_date->startOfDay()) ? "YES" : "NO") . "\n";
    echo "LT_END: " . (now()->lte($book->promotion->end_date->endOfDay()) ? "YES" : "NO") . "\n";
    echo "PROMO_STATUS: " . $book->promotion->status . "\n";
} else {
    echo "NO PROMOTION\n";
}
echo "PRICE: " . $book->price . "\n";
echo "DISCOUNTED: " . ($book->discounted_price ?? 'null') . "\n";
