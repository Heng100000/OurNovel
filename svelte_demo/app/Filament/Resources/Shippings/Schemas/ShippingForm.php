<?php

namespace App\Filament\Resources\Shippings\Schemas;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class ShippingForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('order_id')
                    ->label('Related Order')
                    ->relationship('order', 'id')
                    ->required()
                    ->helperText('Select the order this shipment belongs to.'),
                Select::make('delivery_company_id')
                    ->label('Delivery Provider')
                    ->relationship('deliveryCompany', 'name')
                    ->required()
                    ->preload()
                    ->searchable()
                    ->helperText('Choose the shipping company handled this delivery.'),
                TextInput::make('tracking_no')
                    ->label('Tracking Number')
                    ->placeholder('e.g. JT123456789')
                    ->maxLength(100),
                Select::make('status')
                    ->label('Delivery Status')
                    ->options([
                        'preparing' => 'Preparing',
                        'shipped' => 'Shipped',
                        'delivered' => 'Delivered',
                    ])
                    ->required()
                    ->default('preparing')
                    ->native(false),
            ]);
    }
}
