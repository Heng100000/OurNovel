<?php

namespace App\Http\Resources\Api;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class NewsAnnouncementResource extends JsonResource
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
            'news_type' => $this->relationLoaded('newsType') && $this->newsType ? [
                'id' => $this->newsType->id,
                'name' => $this->newsType->name,
            ] : ($this->newsType ? [
                'id' => $this->newsType->id,
                'name' => $this->newsType->name,
            ] : null),
            'type_news' => $this->newsType?->name ?? 'General', // Keep for backward compatibility if needed
            'image_url' => $this->getOptimizedImageUrl($this->image_url, width: 400),
            'description' => strip_tags($this->description),
            'created_at' => $this->created_at,
        ];
    }
}
