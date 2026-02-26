<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ShippingRateResource extends JsonResource
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
            'delivery_company_id' => $this->delivery_company_id,
            'delivery_company_name' => $this->deliveryCompany->name ?? null,
            'location_name' => $this->location_name,
            'fee' => $this->fee,
            'estimated_days' => $this->estimated_days,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
