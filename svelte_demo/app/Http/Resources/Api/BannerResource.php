<?php

namespace App\Http\Resources\Api;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BannerResource extends JsonResource
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
            'subtitle' => $this->subtitle,
            'description' => $this->description,
            'image_url' => $this->getOptimizedImageUrl($this->image_url, width: 600),
            'discount_percentage' => $this->discount_percentage,
            'button_text' => $this->button_text,
            'action_type' => $this->action_type,
            'action_id' => $this->action_id,
            'action_url' => $this->action_url,
            'display_order' => $this->display_order,
        ];
    }
}
