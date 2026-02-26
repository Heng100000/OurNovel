<?php

namespace App\Filament\Resources\Invoices\Schemas;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class InvoiceForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('General Information')
                    ->description('Reference the original order and set the unique invoice number.')
                    ->icon('heroicon-o-document-plus')
                    ->columns(2)
                    ->schema([
                        Select::make('order_id')
                            ->label('Related Order')
                            ->relationship('order', 'id')
                            ->searchable()
                            ->preload()
                            ->required()
                            ->helperText('Link this invoice to an existing book order.'),
                        TextInput::make('invoice_no')
                            ->label('Invoice Number')
                            ->placeholder('e.g. INV-2024-001')
                            ->required()
                            ->unique(ignoreRecord: true)
                            ->maxLength(255),
                    ]),

                Section::make('Financial Details')
                    ->description('Breakdown of costs including tax and shipping.')
                    ->icon('heroicon-o-banknotes')
                    ->columns(2)
                    ->schema([
                        TextInput::make('sub_total')
                            ->label('Subtotal')
                            ->required()
                            ->numeric()
                            ->prefix('$')
                            ->placeholder('0.00'),
                        TextInput::make('shipping_fee')
                            ->label('Shipping Fee')
                            ->required()
                            ->numeric()
                            ->prefix('$')
                            ->default(0)
                            ->placeholder('0.00'),
                        TextInput::make('tax_amount')
                            ->label('Tax Amount')
                            ->required()
                            ->numeric()
                            ->prefix('$')
                            ->default(0)
                            ->placeholder('0.00'),
                        TextInput::make('grand_total')
                            ->label('Grand Total')
                            ->required()
                            ->numeric()
                            ->prefix('$')
                            ->placeholder('0.00')
                            ->helperText('Final amount to be paid by the customer.'),
                    ]),

                Section::make('Documents')
                    ->description('Manage generated PDF invoices or external links.')
                    ->icon('heroicon-o-paper-clip')
                    ->schema([
                        TextInput::make('pdf_url')
                            ->label('PDF URL')
                            ->url()
                            ->placeholder('https://...')
                            ->helperText('Optional link to the downloadable invoice document.'),
                    ]),
            ]);
    }
}
