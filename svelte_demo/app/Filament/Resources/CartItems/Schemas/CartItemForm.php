<?php

namespace App\Filament\Resources\CartItems\Schemas;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class CartItemForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Cart Item Details')
                    ->description('Manage items currently in customer carts.')
                    ->icon('heroicon-o-shopping-cart')
                    ->schema([
                        Select::make('user_id')
                            ->label('Customer')
                            ->relationship('user', 'name')
                            ->searchable()
                            ->preload()
                            ->prefixIcon('heroicon-o-user')
                            ->required(),
                        Select::make('book_id')
                            ->label('Book')
                            ->relationship('book', 'title')
                            ->searchable()
                            ->preload()
                            ->prefixIcon('heroicon-o-book-open')
                            ->required(),
                        TextInput::make('quantity')
                            ->label('Quantity')
                            ->required()
                            ->numeric()
                            ->minValue(1)
                            ->default(1)
                            ->prefixIcon('heroicon-o-hashtag'),
                    ])->columns(2),
            ]);
    }
}
