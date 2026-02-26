<?php

namespace App\Filament\Resources\DeliveryCompanies\Schemas;

use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Repeater;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class DeliveryCompanyForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Delivery Company')
                    ->description('Fill in the company details and define its shipping rates by destination.')
                    ->icon('heroicon-o-truck')
                    ->columnSpanFull() // Ensure the section itself spans the full form width
                    ->columns(1) // Stack fields to make them "full width" inside the section
                    ->schema([
                        TextInput::make('name')
                            ->label('Company Name')
                            ->placeholder('e.g. J&T Express, DHL, FedEx')
                            ->prefixIcon('heroicon-o-truck')
                            ->required()
                            ->maxLength(100)
                            ->helperText('Enter the full, official name of the delivery company.'),

                        FileUpload::make('logo_path')
                            ->label('Company Logo')
                            ->image()
                            ->disk('public')
                            ->directory('delivery-logos')
                            ->avatar()
                            ->imageEditor()
                            ->helperText('Upload the company logo (PNG, JPG, or SVG).'),

                        TextInput::make('contact_phone')
                            ->label('Contact Phone')
                            ->placeholder('+855 12 345 678')
                            ->prefixIcon('heroicon-o-phone')
                            ->tel()
                            ->helperText('Main customer service number for this carrier.'),

                        Toggle::make('is_active')
                            ->label('Active & Available')
                            ->helperText('Disable to temporarily hide this company from checkout.')
                            ->onColor('success')
                            ->offColor('danger')
                            ->onIcon('heroicon-m-check')
                            ->offIcon('heroicon-m-x-mark')
                            ->required()
                            ->default(true),

                        Repeater::make('shippingRates')
                            ->relationship('shippingRates')
                            ->label('Shipping Rates')
                            ->schema([
                                TextInput::make('location_name')
                                    ->label('Destination / City')
                                    ->placeholder('e.g. Phnom Penh, Siem Reap')
                                    ->prefixIcon('heroicon-o-map-pin')
                                    ->required()
                                    ->maxLength(255)
                                    ->columnSpan(6),

                                TextInput::make('fee')
                                    ->label('Shipping Fee')
                                    ->placeholder('0.00')
                                    ->prefix('$')
                                    ->required()
                                    ->numeric()
                                    ->minValue(0)
                                    ->columnSpan(3),

                                TextInput::make('estimated_days')
                                    ->label('Estimated Delivery')
                                    ->placeholder('3-5')
                                    ->suffix('days')
                                    ->columnSpan(3),
                            ])
                            ->columns(12)
                            ->addActionLabel('+ Add Shipping Destination')
                            ->collapsible()
                            ->collapsed(false)
                            ->defaultItems(1)
                            ->itemLabel(fn (array $state): ?string =>
                                ($state['location_name'] ?? null)
                                    ? '📍 ' . $state['location_name'] . (isset($state['fee']) ? ' — $' . $state['fee'] : '')
                                    : 'New Shipping Rate'
                            )
                            ->reorderableWithButtons()
                            ->cloneable(),
                    ]),
            ]);
    }
}
