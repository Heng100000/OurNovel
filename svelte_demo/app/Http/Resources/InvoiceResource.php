<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class InvoiceResource extends JsonResource
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
            'order_id' => $this->order_id,
            'order' => $this->whenLoaded('order'),
            'invoice_no' => $this->invoice_no,
            'sub_total' => $this->sub_total,
            'shipping_fee' => $this->shipping_fee,
            'tax_amount' => $this->tax_amount,
            'grand_total' => $this->grand_total,
            'pdf_url' => $this->pdf_url,
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
