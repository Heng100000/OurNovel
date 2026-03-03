<?php

use Illuminate\Support\Facades\Route;
use Inertia\Inertia;
use Laravel\Fortify\Features;
use App\Http\Controllers\TaskController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\BookController;
use App\Http\Controllers\AuthorController;
use App\Http\Controllers\PublisherController;

// Route::get('/', function () {
//     return Inertia::render('Welcome', [
//         'canRegister' => Features::enabled(Features::registration()),
//     ]);
// })->name('home');

Route::middleware(['auth', 'verified'])->group(function () {
    Route::get('dashboard', function () {
        return redirect()->route('pos');
    })->name('dashboard');

    Route::resource('categories', CategoryController::class);
    Route::resource('authors', AuthorController::class);
    Route::resource('publishers', PublisherController::class);
    Route::resource('books', BookController::class);
});

require __DIR__.'/settings.php';

// Store Routes (React)
Route::get('/shop/{any?}', function () {
    return view('shop');
})->where('any', '.*')->name('shop');

Route::redirect('/', '/shop');
Route::redirect('/pos', '/shop');

// POS Routes (Legacy)
Route::middleware(['auth', 'verified'])->group(function () {
    Route::get('/pos-legacy', [App\Http\Controllers\PosController::class, 'index'])->name('pos');
    Route::post('/pos/cart', [App\Http\Controllers\PosController::class, 'addToCart'])->name('pos.cart.add');
    Route::post('/pos/cart/update', [App\Http\Controllers\PosController::class, 'updateQuantity'])->name('pos.cart.update');
    Route::delete('/pos/cart/{id}', [App\Http\Controllers\PosController::class, 'removeFromCart'])->name('pos.cart.remove');
    Route::post('/pos/checkout', [App\Http\Controllers\PosController::class, 'checkout'])->name('pos.checkout');
});
