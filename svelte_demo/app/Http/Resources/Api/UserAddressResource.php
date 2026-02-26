<?php

namespace App\Http\Resources\Api;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserAddressResource extends JsonResource
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
            'address' => $this->address,
            'city_province' => $this->city_province,
            'phone' => $this->phone,
            'is_default' => (bool) $this->is_default,
            'latitude' => $this->latitude,
            'longitude' => $this->longitude,
        ];
    }
}
