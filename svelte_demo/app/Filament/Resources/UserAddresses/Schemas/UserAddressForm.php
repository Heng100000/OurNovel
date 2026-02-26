<?php

namespace App\Filament\Resources\UserAddresses\Schemas;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Schema;

class UserAddressForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('user_id')
                    ->relationship('user', 'name')
                    ->required(),
                TextInput::make('title')
                    ->required()
                    ->placeholder('e.g. Home, Office'),
                Select::make('city_province')
                    ->label('City / Province')
                    ->options(\App\Models\ShippingRate::distinct()->pluck('location_name', 'location_name'))
                    ->searchable()
                    ->required()
                    ->createOptionForm([
                        TextInput::make('location_name')
                            ->required(),
                    ])
                    ->helperText('Select a location that has shipping rates defined.'),
                Textarea::make('address')
                    ->required()
                    ->placeholder('Full address details...')
                    ->columnSpanFull(),
                TextInput::make('phone')
                    ->tel()
                    ->required()
                    ->placeholder('Contact number for this address'),
                Toggle::make('is_default')
                    ->required(),
            ]);
    }
}
