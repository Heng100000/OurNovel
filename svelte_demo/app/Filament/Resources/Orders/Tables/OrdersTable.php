<?php

namespace App\Filament\Resources\Orders\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class OrdersTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('user.name')
                    ->searchable(),
                TextColumn::make('address.title')
                    ->searchable(),
                TextColumn::make('payment.method')
                    ->label('Payment')
                    ->badge()
                    ->icon(fn (string $state): string => match (strtolower($state)) {
                        'aba' => 'heroicon-m-building-library',
                        'aceleda' => 'heroicon-m-credit-card',
                        'bakong' => 'heroicon-m-qr-code',
                        'cash' => 'heroicon-m-banknotes',
                        default => 'heroicon-m-credit-card',
                    })
                    ->color(fn (string $state): string => match (strtolower($state)) {
                        'aba' => 'info',
                        'aceleda' => 'warning',
                        'bakong' => 'success',
                        'cash' => 'gray',
                        default => 'primary',
                    })
                    ->formatStateUsing(fn (string $state): string => strtoupper($state))
                    ->sortable(),
                TextColumn::make('total_price')
                    ->money()
                    ->sortable(),
                TextColumn::make('status')
                    ->badge()
                    ->icon(fn (string $state): string => match (strtolower($state)) {
                        'pending' => 'heroicon-m-clock',
                        'processing' => 'heroicon-m-arrow-path',
                        'shipped' => 'heroicon-m-truck',
                        'completed', 'paid' => 'heroicon-m-check-circle',
                        'cancelled' => 'heroicon-m-x-circle',
                        default => 'heroicon-m-question-mark-circle',
                    })
                    ->color(fn (string $state): string => match (strtolower($state)) {
                        'pending' => 'gray',
                        'processing' => 'info',
                        'shipped' => 'warning',
                        'completed', 'paid' => 'success',
                        'cancelled' => 'danger',
                        default => 'primary',
                    })
                    ->formatStateUsing(fn (string $state): string => ucfirst($state))
                    ->searchable(),
                TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                TextColumn::make('updated_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                \Filament\Tables\Filters\SelectFilter::make('payment_method')
                    ->label('Payment Method')
                    ->relationship('payment', 'method')
                    ->options([
                        'aba' => 'ABA',
                        'aceleda' => 'ACELEDA',
                        'bakong' => 'Bakong/KHQR',
                        'cash' => 'Cash on Pickup',
                    ]),
            ])
            ->recordActions([
                EditAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }
}
