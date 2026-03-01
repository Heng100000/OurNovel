<?php

use App\Models\Book;
use App\Models\CartItem;
use App\Models\Promotion;
use App\Models\User;
use Illuminate\Support\Carbon;

// Find or create a user
$user = User::first() ?? User::factory()->create();

// Create a mock promotion that is currently active
$promotion = Promotion::create([
    'event_name' => 'Test Promo Active',
    'status' => 'active',
    'discount_type' => 'percentage',
    'discount_value' => 50, // 50% off
    'start_date' => Carbon::now()->subDay(),
    'end_date' => Carbon::now()->addDay(),
]);

$book = Book::create([
    'title' => 'Cart Pricing Test Book',
    'price' => 100.00,
    'promotion_id' => $promotion->id,
    'stock_qty' => 10,
    'isbn' => 'TEST_ISBN_'.rand(1000, 9999),
    'description' => 'A test book to verify cart pricing',
    'condition' => 'new',
    'category_id' => App\Models\Category::first()->id ?? 1,
    'author_id' => App\Models\Author::first()->id ?? 1,
]);

echo 'Initial Book Price (calculated on-the-fly): '.$book->discounted_price." (expected: 50.00)\n";

// Add book to cart
$cartItem = CartItem::create([
    'user_id' => $user->id,
    'book_id' => $book->id,
    'quantity' => 1,
    'unit_price' => $book->discounted_price ?? $book->price,
]);

echo 'Price saved in cart_items table: '.$cartItem->unit_price." (expected: 50.00)\n";

// Wait, simulate promotion expiry
echo "Simulating promotion expiry...\n";
$promotion->update([
    'end_date' => Carbon::now()->subDays(2), // Expired 2 days ago
]);

// Reload book & cart item
$book->refresh();
$cartItem->refresh();

echo 'After Expiry - Current Book Discounted Price: '.($book->discounted_price ?? 'null')."\n";
echo 'After Expiry - Price locked in cart: '.$cartItem->unit_price." (expected: 50.00)\n";

// Test Resource Representation
$request = request();
$resource = new App\Http\Resources\CartItemResource($cartItem);
$array = $resource->toArray($request);

echo 'API Resource unit_price: '.$array['unit_price']." (expected: 50.00)\n";

// Clean up
$cartItem->delete();
$book->delete();
$promotion->delete();

echo "Verification Complete!\n";
