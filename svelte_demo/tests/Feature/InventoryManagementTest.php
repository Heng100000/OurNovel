<?php

use App\Models\Book;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\User;
use App\Models\Category;
use App\Models\Author;
use App\Models\DeliveryCompany;
use App\Models\UserAddress;
use App\Models\CartItem;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

test('stock decreases when an order item is created', function () {
    $category = Category::create(['name' => 'Test Category']);
    $author = Author::create(['name' => 'Test Author']);
    
    $book = Book::create([
        'category_id' => $category->id,
        'author_id' => $author->id,
        'title' => 'Test Book',
        'description' => 'Test Description',
        'price' => 10.00,
        'condition' => 'Brand New',
        'stock_qty' => 10,
        'status' => 'active'
    ]);

    $user = User::factory()->create();
    $address = UserAddress::create([
        'user_id' => $user->id,
        'title' => 'Home',
        'phone' => '012345678',
        'address' => 'Street 123',
        'city_province' => 'Phnom Penh',
        'is_default' => true
    ]);
    
    $delivery = DeliveryCompany::create(['name' => 'J&T']);

    $order = Order::create([
        'user_id' => $user->id,
        'address_id' => $address->id,
        'delivery_company_id' => $delivery->id,
        'subtotal' => 10.00,
        'shipping_fee' => 1.00,
        'total_price' => 11.00,
        'status' => 'Pending'
    ]);

    OrderItem::create([
        'order_id' => $order->id,
        'book_id' => $book->id,
        'quantity' => 2,
        'unit_price' => 10.00
    ]);

    $book->refresh();
    expect($book->stock_qty)->toBe(8);
});

test('stock increases when an order item is deleted', function () {
    $category = Category::create(['name' => 'Test Category']);
    $author = Author::create(['name' => 'Test Author']);
    
    $book = Book::create([
        'category_id' => $category->id,
        'author_id' => $author->id,
        'title' => 'Test Book',
        'description' => 'Test Description',
        'price' => 10.00,
        'condition' => 'Brand New',
        'stock_qty' => 10,
        'status' => 'active'
    ]);

    $user = User::factory()->create();
    $address = UserAddress::create([
        'user_id' => $user->id,
        'title' => 'Home',
        'phone' => '012345678',
        'address' => 'Street 123',
        'city_province' => 'Phnom Penh',
        'is_default' => true
    ]);
    
    $delivery = DeliveryCompany::create(['name' => 'J&T']);

    $order = Order::create([
        'user_id' => $user->id,
        'address_id' => $address->id,
        'delivery_company_id' => $delivery->id,
        'subtotal' => 10.00,
        'shipping_fee' => 1.00,
        'total_price' => 11.00,
        'status' => 'Pending'
    ]);

    $item = OrderItem::create([
        'order_id' => $order->id,
        'book_id' => $book->id,
        'quantity' => 2,
        'unit_price' => 10.00
    ]);

    $item->delete();

    $book->refresh();
    expect($book->stock_qty)->toBe(10);
});

test('order creation fails if stock is insufficient', function () {
    $category = Category::create(['name' => 'Test Category']);
    $author = Author::create(['name' => 'Test Author']);
    
    $book = Book::create([
        'category_id' => $category->id,
        'author_id' => $author->id,
        'title' => 'Test Book',
        'description' => 'Test Description',
        'price' => 10.00,
        'condition' => 'Brand New',
        'stock_qty' => 1,
        'status' => 'active'
    ]);

    $user = User::factory()->create();
    $address = UserAddress::create([
        'user_id' => $user->id,
        'title' => 'Home',
        'phone' => '012345678',
        'address' => 'Street 123',
        'city_province' => 'Phnom Penh',
        'is_default' => true
    ]);
    
    $delivery = DeliveryCompany::create(['name' => 'J&T']);

    // Create cart item
    CartItem::create([
        'user_id' => $user->id,
        'book_id' => $book->id,
        'quantity' => 2 // Requesting more than stock
    ]);

    $response = $this->actingAs($user)->postJson('/api/orders', [
        'address_id' => $address->id,
        'delivery_company_id' => $delivery->id
    ]);

    $response->assertStatus(422);
    $response->assertJsonPath('error', 'out_of_stock');
});
