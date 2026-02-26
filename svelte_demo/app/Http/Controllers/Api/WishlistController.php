<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Wishlist;
use Illuminate\Http\Request;
use App\Http\Resources\Api\WishlistResource;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

use Illuminate\Http\JsonResponse;

class WishlistController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $wishlist = $request->user()->wishlistItems()->with(['book.author', 'book.images'])->get();
        return WishlistResource::collection($wishlist);
    }

    public function store(Request $request): WishlistResource
    {
        $request->validate([
            'book_id' => 'required|exists:books,id',
        ]);

        $wishlistItem = $request->user()->wishlistItems()->firstOrCreate([
            'book_id' => $request->book_id
        ]);

        $wishlistItem->load(['book.author', 'book.images']);

        return new WishlistResource($wishlistItem);
    }

    public function destroy(Request $request, int $bookId): JsonResponse
    {
        $request->user()->wishlistItems()->where('book_id', $bookId)->delete();
        return response()->json(null, 204);
    }
}
