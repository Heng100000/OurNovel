<?php

namespace App\Http\Resources\Api;

use App\Services\BakongService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PaymentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'         => $this->id,
            'order_id'   => $this->order_id,
            'method'     => $this->method,
            'amount'     => (float) $this->amount,
            'status'     => $this->status,
            'txn_id'     => $this->txn_id,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
            'order'      => $this->whenLoaded('order', fn () => [
                'id'          => $this->order->id,
                'total_price' => (float) $this->order->total_price,
                'status'      => $this->order->status,
            ]),
            'qr_code'    => $this->when(isset($this->qr_code), fn () => $this->qr_code),
            'deep_link'  => $this->when(isset($this->deep_link), fn () => $this->deep_link),
            'qr_image_url' => $this->when(isset($this->qr_image_url), fn () => $this->qr_image_url),
        ];
    }
}
