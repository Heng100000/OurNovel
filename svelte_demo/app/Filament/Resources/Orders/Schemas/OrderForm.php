<?php

namespace App\Filament\Resources\Orders\Schemas;

use App\Models\Book;
use App\Models\CartItem;
use Filament\Forms\Components\Placeholder;
use Filament\Forms\Components\Repeater;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Components\Utilities\Get;
use Filament\Schemas\Components\Utilities\Set;
use Filament\Schemas\Schema;

class OrderForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Order Information')
                    ->description('Assign the customer and shipping address for this order.')
                    ->icon('heroicon-o-shopping-bag')
                    ->columns(2)
                    ->schema([
                        Select::make('user_id')
                            ->label('Customer')
                            ->relationship('user', 'name')
                            ->searchable()
                            ->preload()
                            ->required()
                            ->live()
                            ->afterStateUpdated(function (Set $set, ?string $state) {
                                if (! $state) {
                                    $set('items', []);
                                    static::updateTotalPrice(null, $set);

                                    return;
                                }

                                $cartItems = CartItem::where('user_id', $state)
                                    ->with('book')
                                    ->get();

                                if ($cartItems->isEmpty()) {
                                    $set('items', []);
                                    static::updateTotalPrice(null, $set);

                                    return;
                                }

                                $items = $cartItems->map(function ($item) {
                                    $unitPrice = $item->book->discounted_price ?? $item->book->price ?? 0;
                                    $quantity = $item->quantity;

                                    return [
                                        'book_id' => $item->book_id,
                                        'quantity' => $quantity,
                                        'unit_price' => $unitPrice,
                                        'item_total' => number_format($quantity * $unitPrice, 2, '.', ''),
                                    ];
                                })->toArray();

                                $set('items', $items);
                            })
                            ->afterStateUpdated(fn (Get $get, Set $set) => static::updateTotalPrice($get, $set)),
                        Select::make('address_id')
                            ->label('Shipping Address')
                            ->relationship('address', 'title')
                            ->searchable()
                            ->preload()
                            ->required()
                            ->helperText('Select the specific address for delivery.'),
                        Select::make('delivery_company_id')
                            ->label('Delivery Company')
                            ->relationship('deliveryCompany', 'name')
                            ->searchable()
                            ->preload()
                            ->required(),
                        Select::make('status')
                            ->label('Order Status')
                            ->options([
                                'pending' => 'Pending',
                                'processing' => 'Processing',
                                'shipped' => 'Shipped',
                                'completed' => 'Completed',
                                'paid' => 'Paid',
                                'cancelled' => 'Cancelled',
                            ])
                            ->required()
                            ->default('pending')
                            ->native(false),
                    ]),

                Section::make('Financial Details')
                    ->description('Overview of order costs.')
                    ->icon('heroicon-o-currency-dollar')
                    ->columns(3)
                    ->schema([
                        TextInput::make('subtotal')
                            ->label('Subtotal')
                            ->required()
                            ->numeric()
                            ->prefix('$')
                            ->readOnly()
                            ->default(0.00),
                        TextInput::make('shipping_fee')
                            ->label('Shipping Fee')
                            ->required()
                            ->numeric()
                            ->prefix('$')
                            ->default(0.00)
                            ->live()
                            ->afterStateUpdated(fn (Get $get, Set $set) => static::updateTotalPrice($get, $set)),
                        TextInput::make('total_price')
                            ->label('Grand Total')
                            ->required()
                            ->numeric()
                            ->prefix('$')
                            ->readOnly()
                            ->default(0.00),
                        Placeholder::make('payment_info')
                            ->label('Payment Information')
                            ->content(function ($record) {
                                if (! $record?->payment) {
                                    return new \Illuminate\Support\HtmlString('<span class="fi-badge fi-color-gray flex items-center gap-x-1 px-2 py-1 text-xs font-semibold rounded-full bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400">Not Paid</span>');
                                }

                                $method = strtolower($record->payment->method);
                                $label = strtoupper($method === 'bakong' ? 'KHQR' : $method);
                                $color = match ($method) {
                                    'aba' => '#005aab',
                                    'aceleda' => '#1b365d',
                                    'bakong' => '#0f7a47',
                                    'cash' => '#6b7280',
                                    default => '#0f7a47',
                                };

                                return new \Illuminate\Support\HtmlString("
                                    <div class='flex items-center gap-2'>
                                        <span style='background-color: {$color}; color: white;' class='px-2 py-1 text-xs font-bold rounded-full'>
                                            {$label}
                                        </span>
                                        <span class='text-sm text-gray-500'>
                                            ID: {$record->payment->id}
                                        </span>
                                    </div>
                                ");
                            }),
                    ]),

                Section::make('Order Items')
                    ->description('Add books to this order. Quantity and price will be recorded below.')
                    ->icon('heroicon-o-list-bullet')
                    ->schema([
                        Repeater::make('items')
                            ->relationship('items')
                            ->schema([
                                Select::make('book_id')
                                    ->label('Book')
                                    ->relationship('book', 'title')
                                    ->searchable()
                                    ->preload()
                                    ->required()
                                    ->live()
                                    ->afterStateUpdated(function (Get $get, Set $set, ?string $state) {
                                        if (! $state) {
                                            return;
                                        }

                                        $book = Book::find($state);
                                        $price = $book?->discounted_price ?? $book?->price ?? 0;
                                        $set('unit_price', $price);

                                        $set('item_total', number_format(($get('quantity') ?? 1) * $price, 2, '.', ''));
                                        static::updateTotalPrice($get, $set);
                                    })
                                    ->columnSpan(4),
                                TextInput::make('quantity')
                                    ->label('Qty')
                                    ->numeric()
                                    ->default(1)
                                    ->required()
                                    ->live()
                                    ->afterStateUpdated(function (Get $get, Set $set, ?string $state) {
                                        $set('item_total', number_format(($state ?? 1) * ($get('unit_price') ?? 0), 2, '.', ''));
                                        static::updateTotalPrice($get, $set);
                                    })
                                    ->columnSpan(2),
                                TextInput::make('unit_price')
                                    ->label('Unit Price')
                                    ->numeric()
                                    ->prefix('$')
                                    ->required()
                                    ->live()
                                    ->afterStateUpdated(function (Get $get, Set $set, ?string $state) {
                                        $set('item_total', number_format(($get('quantity') ?? 1) * ($state ?? 0), 2, '.', ''));
                                        static::updateTotalPrice($get, $set);
                                    })
                                    ->columnSpan(3),
                                TextInput::make('item_total')
                                    ->label('Subtotal')
                                    ->numeric()
                                    ->prefix('$')
                                    ->readOnly()
                                    ->extraInputAttributes(['tabindex' => '-1'])
                                    ->afterStateHydrated(function (Set $set, Get $get, $state) {
                                        $set('item_total', number_format(($get('quantity') ?? 1) * ($get('unit_price') ?? 0), 2, '.', ''));
                                    })
                                    ->columnSpan(3),
                            ])
                            ->columns(12)
                            ->addActionLabel('Add Book to Order')
                            ->collapsible()
                            ->defaultItems(1)
                            ->live()
                            ->afterStateUpdated(fn (Get $get, Set $set) => static::updateTotalPrice($get, $set))
                            ->deleteAction(fn ($action) => $action->after(fn (Get $get, Set $set) => static::updateTotalPrice($get, $set))),
                    ]),
            ]);
    }

    protected static function updateTotalPrice(?Get $get, Set $set): void
    {
        $items = $get ? ($get('items') ?? []) : [];

        $subtotal = collect($items)->reduce(function ($carry, $item) {
            return $carry + ($item['quantity'] ?? 0) * ($item['unit_price'] ?? 0);
        }, 0);

        $shippingFee = floatval($get ? ($get('shipping_fee') ?? 0) : 0);
        $total = $subtotal + $shippingFee;

        $set('subtotal', number_format($subtotal, 2, '.', ''));
        $set('total_price', number_format($total, 2, '.', ''));
    }
}
