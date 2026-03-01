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
        return Inertia::render('Dashboard');
    })->name('dashboard');

    Route::resource('categories', CategoryController::class);
    Route::resource('authors', AuthorController::class);
    Route::resource('publishers', PublisherController::class);
    Route::resource('books', BookController::class);
});

require __DIR__.'/settings.php';

Route::get('/', [TaskController::class, 'index'])->name('home');
Route::post('/tasks', [TaskController::class, 'store'])->name('tasks.store');

// Public News Sharing Route
Route::get('/news/{newsAnnouncement}', [\App\Http\Controllers\Web\NewsAnnouncementController::class, 'show'])->name('news.show');
