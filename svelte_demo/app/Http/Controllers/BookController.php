<?php

namespace App\Http\Controllers;

use App\Models\Author;
use App\Models\Book;
use App\Models\Category;
use App\Models\Publisher;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class BookController extends Controller
{
    public function index(): Response
    {
        return Inertia::render('Book/Index', [
            'books' => Book::with(['category', 'author', 'publisher'])->get(),
            'categories' => Category::all(),
            'authors' => Author::all(),
            'publishers' => Publisher::all(),
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'slug' => 'required|string|max:255|unique:books',
            'isbn' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'published_at' => 'nullable|date',
            'price' => 'nullable|numeric|min:0',
            'page_count' => 'nullable|integer|min:0',
            'language' => 'nullable|string|max:255',
            'author_id' => 'required|exists:authors,id',
            'category_id' => 'required|exists:categories,id',
            'publisher_id' => 'required|exists:publishers,id',
        ]);

        Book::create($validated);

        return back();
    }
}
