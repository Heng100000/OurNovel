<?php

namespace App\Filament\Resources\Promotions\Schemas;

use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class PromotionForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                // ── Promotion Details ────────────────────────────────────
                Section::make('Promotion Details')
                    ->description('Define the promotion name and link it to a parent event.')
                    ->icon('heroicon-o-tag')
                    ->schema([
                        Select::make('event_id')
                            ->label('Parent Event')
                            ->relationship('event', 'title')
                            ->searchable()
                            ->preload()
                            ->live()
                            ->afterStateUpdated(function ($state, callable $set): void {
                                if (! $state) {
                                    return;
                                }

                                $event = \App\Models\Event::find($state);

                                if (! $event) {
                                    return;
                                }

                                $set('start_date', $event->start_date?->format('Y-m-d H:i'));
                                $set('end_date', $event->end_date?->format('Y-m-d H:i'));
                            })
                            ->helperText('Selecting an event will auto-fill the dates below.')
                            ->columnSpanFull(),

                        TextInput::make('event_name')
                            ->label('Promotion Name')
                            ->placeholder('e.g. Ramadan Sale, Flash Deal')
                            ->required()
                            ->maxLength(255)
                            ->columnSpanFull(),
                    ]),

                // ── Discount Configuration ────────────────────────────────
                Section::make('Discount Configuration')
                    ->description('Set the discount type and the value that will be applied.')
                    ->icon('heroicon-o-currency-dollar')
                    ->schema([
                        Grid::make(2)
                            ->schema([
                                Select::make('discount_type')
                                    ->label('Discount Type')
                                    ->options([
                                        'percentage' => '% Percentage',
                                        'fixed'      => 'Fixed Amount (Rp)',
                                    ])
                                    ->required()
                                    ->native(false)
                                    ->helperText('Choose how the discount is calculated.'),

                                TextInput::make('discount_value')
                                    ->label('Discount Value')
                                    ->placeholder('e.g. 10 for 10% or 50000 for Rp 50,000')
                                    ->required()
                                    ->numeric()
                                    ->minValue(0)
                                    ->helperText('Enter a number — percentage or fixed amount.'),
                            ]),
                    ]),

                // ── Schedule & Status ────────────────────────────────────
                Section::make('Schedule & Status')
                    ->description('Define the active period and current state of this promotion.')
                    ->icon('heroicon-o-calendar-days')
                    ->schema([
                        Grid::make(2)
                            ->schema([
                                DateTimePicker::make('start_date')
                                    ->label('Start Date & Time')
                                    ->helperText('When does this promotion go live?')
                                    ->hint('Inclusive')
                                    ->hintIcon('heroicon-m-information-circle')
                                    ->native(false)
                                    ->prefixIcon('heroicon-o-arrow-right-circle')
                                    ->displayFormat('M d, Y h:i A')
                                    ->seconds(false)
                                    ->required(),

                                DateTimePicker::make('end_date')
                                    ->label('End Date & Time')
                                    ->helperText('When does this promotion expire?')
                                    ->hint('Inclusive')
                                    ->hintIcon('heroicon-m-information-circle')
                                    ->native(false)
                                    ->prefixIcon('heroicon-o-x-circle')
                                    ->displayFormat('M d, Y h:i A')
                                    ->seconds(false)
                                    ->after('start_date')
                                    ->required(),
                            ]),

                        Select::make('status')
                            ->label('Promotion Status')
                            ->options([
                                'active'   => 'Active',
                                'inactive' => 'Inactive',
                                'expired'  => 'Expired',
                            ])
                            ->required()
                            ->native(false)
                            ->default('active')
                            ->helperText('Only active promotions are applied at checkout.'),
                    ]),
            ]);
    }
}
