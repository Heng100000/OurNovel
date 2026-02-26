<?php

namespace App\Filament\Resources\Orders\RelationManagers;

use App\Models\DeliveryCompany;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\CreateAction;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Schemas\Schema;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class ShippingRelationManager extends RelationManager
{
    protected static string $relationship = 'shipping';

    public function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('delivery_company_id')
                    ->label('Delivery Company')
                    ->relationship('deliveryCompany', 'name')
                    ->searchable()
                    ->preload()
                    ->required(),
                TextInput::make('tracking_no')
                    ->label('Tracking Number')
                    ->placeholder('e.g. JNT123456789')
                    ->maxLength(255),
                Select::make('status')
                    ->label('Shipping Status')
                    ->options([
                        'pending' => 'Pending',
                        'processing' => 'Processing',
                        'shipped' => 'Shipped',
                        'delivered' => 'Delivered',
                        'failed' => 'Failed',
                    ])
                    ->required()
                    ->default('pending'),
            ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('tracking_no')
            ->columns([
                TextColumn::make('deliveryCompany.name')
                    ->label('Carrier')
                    ->sortable(),
                TextColumn::make('tracking_no')
                    ->label('Tracking #')
                    ->searchable()
                    ->placeholder('N/A'),
                TextColumn::make('status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'pending' => 'gray',
                        'processing' => 'info',
                        'shipped' => 'warning',
                        'delivered' => 'success',
                        'failed' => 'danger',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => ucfirst($state)),
            ])
            ->filters([
                //
            ])
            ->headerActions([
                CreateAction::make(),
            ])
            ->recordActions([
                EditAction::make(),
                DeleteAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }
}
