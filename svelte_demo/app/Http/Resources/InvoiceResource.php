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
            'id'           => $this->id,
            'order_id'     => $this->order_id,
            'invoice_no'   => $this->invoice_no,
            'sub_total'    => $this->sub_total,
            'shipping_fee' => $this->shipping_fee,
            'tax_amount'   => $this->tax_amount,
            'grand_total'  => $this->grand_total,
            'pdf_url'      => $this->pdf_url,
            'created_at'   => $this->created_at,
            'updated_at'   => $this->updated_at,

            'order' => $this->whenLoaded('order', function () {
                $order = $this->order;
                return [
                    'id'              => $order->id,
                    'status'          => $order->status,
                    'delivery_method' => $order->delivery_method,
                    'subtotal'        => $order->subtotal,
                    'shipping_fee'    => $order->shipping_fee,
                    'total_price'     => $order->total_price,

                    'user' => $order->relationLoaded('user') && $order->user ? [
                        'id'    => $order->user->id,
                        'name'  => $order->user->name,
                        'email' => $order->user->email,
                        'phone' => $order->user->phone ?? null,
                    ] : null,

                    'address' => $order->relationLoaded('address') && $order->address ? [
                        'id'              => $order->address->id,
                        'address_details' => $order->address->address_details ?? null,
                        'city'            => $order->address->city ?? null,
                        'latitude'        => $order->address->latitude ?? null,
                        'longitude'       => $order->address->longitude ?? null,
                    ] : null,

                    'order_items' => $order->relationLoaded('items') ? $order->items->map(function ($item) {
                        $book = $item->relationLoaded('book') ? $item->book : null;
                        $unitPrice = (float) ($item->unit_price ?? 0);
                        $quantity  = (int)   ($item->quantity ?? 1);
                        return [
                            'id'          => $item->id,
                            'quantity'    => $quantity,
                            'price'       => number_format($unitPrice, 2, '.', ''),
                            'total_price' => number_format($unitPrice * $quantity, 2, '.', ''),
                            'book'        => $book ? [
                                'id'     => $book->id,
                                'title'  => $book->title,
                                'author' => $book->author ?? null,
                                'isbn'   => $book->isbn ?? null,
                                'images' => $book->relationLoaded('images') ? $book->images->map(fn($img) => [
                                    'id'        => $img->id,
                                    'image_url' => $img->image_url,
                                ])->values()->toArray() : [],
                            ] : null,
                        ];
                    })->values()->toArray() : [],

                    'delivery_company' => $order->relationLoaded('deliveryCompany') && $order->deliveryCompany ? [
                        'id'        => $order->deliveryCompany->id,
                        'name'      => $order->deliveryCompany->name ?? null,
                        'logo_path' => $order->deliveryCompany->logo_path ?? null,
                    ] : null,

                    'payment' => $order->relationLoaded('payment') && $order->payment ? [
                        'id'             => $order->payment->id,
                        'method'         => $order->payment->method ?? null,
                        'status'         => $order->payment->status ?? null,
                        'amount'         => $order->payment->amount ?? null,
                        'transaction_id' => $order->payment->transaction_id ?? null,
                        'paid_at'        => $order->payment->paid_at ?? null,
                    ] : null,
                ];
            }),
        ];
    }
}
