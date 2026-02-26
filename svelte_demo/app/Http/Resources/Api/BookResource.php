<?php

namespace App\Http\Resources\Api;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BookResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'isbn' => $this->isbn,
            'description' => $this->description,
            'price' => $this->price,
            'condition' => $this->condition,
            'stock_qty' => $this->stock_qty,
            'author_id' => $this->author_id,
            'category_id' => $this->category_id,
            'status' => $this->status,
            'video_url' => $this->video_url,
            'discounted_price' => $this->discounted_price,
            'average_rating' => $this->when(isset($this->reviews_avg_rating), round($this->reviews_avg_rating ?? 0, 1)),
            'review_count' => $this->when(isset($this->reviews_count), $this->reviews_count),
            'user_rating' => $this->whenLoaded('reviews', function () {
                return $this->reviews->firstWhere('user_id', auth('sanctum')->id())?->rating;
            }),
            'author' => new AuthorResource($this->whenLoaded('author')),
            'category' => new CategoryResource($this->whenLoaded('category')),
            'promotion' => $this->whenLoaded('promotion'),
            'images' => $this->whenLoaded('images', function() {
                return $this->images->map(function($image) {
                    return [
                        'id' => $image->id,
                        'image_url' => $image->getOptimizedImageUrl($image->image_url, width: 300),
                        'is_primary' => $image->is_primary,
                    ];
                });
            }),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
