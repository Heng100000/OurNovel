<?php

namespace App\Filament\Resources\Payments\Schemas;

use App\Models\Order;
use Filament\Forms\Components\Placeholder;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class PaymentForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                // ── Order ─────────────────────────────────────────────────
                Section::make('Order')
                    ->icon('heroicon-o-shopping-bag')
                    ->schema([
                        Select::make('order_id')
                            ->label('Select Order')
                            ->relationship('order', 'id')
                            ->searchable()
                            ->preload()
                            ->required()
                            ->live()
                            ->afterStateUpdated(function ($state, callable $set) {
                                if ($state) {
                                    $order = Order::find($state);
                                    $set('amount', $order?->total_price);
                                }
                            })
                            ->getOptionLabelFromRecordUsing(
                                fn ($record) => "Order #{$record->id} — {$record->user?->name}"
                            )
                            ->placeholder('Search by order ID or customer name...')
                            ->prefixIcon('heroicon-m-magnifying-glass'),

                        Placeholder::make('order_summary')
                            ->label('Items')
                            ->content(function ($get) {
                                $orderId = $get('order_id');
                                if (! $orderId) {
                                    return 'Select an order to see items.';
                                }

                                $order = Order::with('items.book')->find($orderId);

                                if (! $order?->items->count()) {
                                    return '(No items found)';
                                }

                                return $order->items->map(
                                    fn ($i) => "• {$i->book?->title} × {$i->quantity} — Rp " . number_format((float) $i->unit_price, 2, ',', '.')
                                )->join("\n");
                            }),
                    ]),

                // ── Payment ───────────────────────────────────────────────
                Section::make('Payment')
                    ->icon('heroicon-o-credit-card')
                    ->schema([
                        Grid::make(2)
                            ->schema([
                                Select::make('method')
                                    ->label('Payment Method')
                                    ->required()
                                    ->prefixIcon('heroicon-m-credit-card')
                                    ->native(false)
                                    ->options([
                                        'aba'     => 'ABA',
                                        'aceleda' => 'ACELEDA',
                                    ])
                                    ->placeholder('Select method...'),

                                Select::make('status')
                                    ->label('Status')
                                    ->required()
                                    ->default('pending')
                                    ->native(false)
                                    ->prefixIcon('heroicon-m-check-circle')
                                    ->options([
                                        'pending'   => 'Pending',
                                        'paid'      => 'Paid',
                                        'failed'    => 'Failed',
                                        'cancelled' => 'Cancelled',
                                    ]),

                                TextInput::make('amount')
                                    ->label('Amount (Rp)')
                                    ->required()
                                    ->numeric()
                                    ->prefix('Rp')
                                    ->minValue(0)
                                    ->prefixIcon('heroicon-m-currency-dollar')
                                    ->helperText('Auto-filled from order total.'),

                                TextInput::make('txn_id')
                                    ->label('Transaction ID')
                                    ->placeholder('e.g. TXN-20260222-001')
                                    ->prefixIcon('heroicon-m-hashtag')
                                    ->helperText('Reference from payment gateway.'),
                            ]),
                    ]),
            ]);
    }
}
