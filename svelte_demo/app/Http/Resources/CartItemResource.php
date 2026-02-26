<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CartItemResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $unitPrice = $this->book->discounted_price ?? $this->book->price ?? 0;
        $quantity = $this->quantity;

        return [
            'id' => $this->id,
            'user_id' => $this->user_id,
            'book_id' => $this->book_id,
            'book_title' => $this->book->title ?? null,
            'book_image' => ($image = $this->book->primaryImage ?? $this->book->images->first()) 
                ? $image->getOptimizedImageUrl($image->image_url, width: 200) 
                : null,
            'quantity' => $quantity,
            'unit_price' => $unitPrice,
            'item_total' => number_format($quantity * $unitPrice, 2, '.', ''),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
