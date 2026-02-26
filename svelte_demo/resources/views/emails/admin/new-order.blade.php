<x-mail::message>
# New Order Received

Hello Admin,

A new order has been placed on the bookstore.

**Order Details:**
- **Order ID:** #{{ $order->id }}
- **Customer:** {{ $order->user->name }}
- **Subtotal:** ${{ number_format($order->subtotal, 2) }}
- **Shipping Fee:** ${{ number_format($order->shipping_fee, 2) }}
- **Total Price:** ${{ number_format($order->total_price, 2) }}

**Items:**
@foreach($order->items as $item)
- {{ $item->book->title }} (x{{ $item->quantity }}) - ${{ number_format($item->unit_price, 2) }}
@endforeach

<x-mail::button :url="config('app.url') . '/admin/orders/' . $order->id">
View Order in Dashboard
</x-mail::button>

Thanks,<br>
{{ config('app.name') }}
</x-mail::message>
