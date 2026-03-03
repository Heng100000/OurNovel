<?php

use App\Models\Author;
use App\Models\Book;
use App\Models\Category;
use App\Models\User;
use App\Livewire\Pos;
use Livewire\Livewire;

beforeEach(function () {
    $this->user = User::factory()->create(['role' => 'admin']);
    $this->author = Author::create(['name' => 'Test Author']);
    $this->category = Category::create(['name' => 'Test Category']);
    $this->book = Book::create([
        'title' => 'Test Book',
        'author_id' => $this->author->id,
        'category_id' => $this->category->id,
        'price' => 10.00,
        'stock_qty' => 10,
        'status' => 'active',
        'description' => 'Test Description',
        'condition' => 'new',
    ]);
});

it('renders the pos component', function () {
    $this->actingAs($this->user);
    
    Livewire::test(Pos::class)
        ->assertStatus(200)
        ->assertSee('OurNovel POS')
        ->assertSee('Test Book');
});

it('can filter books by author', function () {
    $this->actingAs($this->user);
    
    $otherAuthor = Author::create(['name' => 'Other Author']);
    $otherBook = Book::create([
        'title' => 'Other Book',
        'author_id' => $otherAuthor->id,
        'category_id' => $this->category->id,
        'price' => 15.00,
        'stock_qty' => 5,
        'status' => 'active',
        'description' => 'Other Description',
        'condition' => 'new',
    ]);

    Livewire::test(Pos::class)
        ->set('selectedAuthorId', $this->author->id)
        ->assertSee('Test Book')
        ->assertDontSee('Other Book');
});

it('can add items to cart', function () {
    $this->actingAs($this->user);

    Livewire::test(Pos::class)
        ->call('addToCart', $this->book->id)
        ->assertSet('cart.' . $this->book->id . '.quantity', 1)
        ->assertSee('Test Book')
        ->assertSee('$10.00');
});

it('calculates subtotal correctly', function () {
    $this->actingAs($this->user);

    Livewire::test(Pos::class)
        ->call('addToCart', $this->book->id)
        ->call('incrementQuantity', $this->book->id)
        ->assertSet('cart.' . $this->book->id . '.quantity', 2)
        ->assertSee('$20.00');
});
