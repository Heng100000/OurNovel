<?php

namespace App\Filament\Resources\Coupons\Schemas;

use Filament\Schemas\Schema;

class CouponForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                \Filament\Schemas\Components\Section::make('Coupon Details')
                    ->schema([
                        \Filament\Forms\Components\TextInput::make('code')
                            ->required()
                            ->unique(ignoreRecord: true)
                            ->maxLength(255)
                            ->helperText('The code customers will enter at checkout.')
                            ->columnSpan(['md' => 1]),

                        \Filament\Forms\Components\Select::make('type')
                            ->options([
                                'fixed' => 'Fixed Amount',
                                'percentage' => 'Percentage',
                            ])
                            ->required()
                            ->default('fixed')
                            ->columnSpan(['md' => 1]),

                        \Filament\Forms\Components\TextInput::make('amount')
                            ->required()
                            ->numeric()
                            ->minValue(0)
                            ->prefix('$ or %')
                            ->columnSpan(['md' => 1]),

                        \Filament\Forms\Components\TextInput::make('min_spend')
                            ->numeric()
                            ->minValue(0)
                            ->prefix('$')
                            ->helperText('Minimum cart subtotal required to use this coupon.')
                            ->columnSpan(['md' => 1]),
                    ])->columns(['md' => 2]),

                \Filament\Schemas\Components\Section::make('Usage & Expiration')
                    ->schema([
                        \Filament\Forms\Components\DateTimePicker::make('valid_from')
                            ->columnSpan(['md' => 1]),

                        \Filament\Forms\Components\DateTimePicker::make('valid_until')
                            ->columnSpan(['md' => 1]),

                        \Filament\Forms\Components\TextInput::make('usage_limit')
                            ->numeric()
                            ->minValue(1)
                            ->helperText('Total times this coupon can be used across all customers.')
                            ->columnSpan(['md' => 1]),

                        \Filament\Forms\Components\TextInput::make('used_count')
                            ->numeric()
                            ->default(0)
                            ->disabled()
                            ->columnSpan(['md' => 1]),

                        \Filament\Forms\Components\Toggle::make('is_active')
                            ->default(true)
                            ->columnSpanFull(),
                    ])->columns(['md' => 2]),
            ]);
    }
}
