<?php

namespace App\Filament\Resources\Invoices\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Actions\Action;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use App\Models\Invoice;

class InvoicesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('order.id')
                    ->searchable(),
                TextColumn::make('invoice_no')
                    ->searchable(),
                TextColumn::make('sub_total')
                    ->numeric()
                    ->sortable(),
                TextColumn::make('shipping_fee')
                    ->numeric()
                    ->sortable(),
                TextColumn::make('tax_amount')
                    ->numeric()
                    ->sortable(),
                TextColumn::make('grand_total')
                    ->numeric()
                    ->sortable(),
                TextColumn::make('pdf_url')
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
                //
            ])
            ->recordActions([
                EditAction::make(),
                Action::make('sendTelegram')
                    ->label('Send via Bot')
                    ->icon('heroicon-o-paper-airplane')
                    ->color('success')
                    ->action(function (Invoice $record, \App\Services\TelegramService $telegramService) {
                        $record->load(['order.items.book', 'order.user']);
                        $chatId = $record->order?->user?->telegram_chat_id;

                        if (! $chatId) {
                            \Filament\Notifications\Notification::make()
                                ->title('Telegram Chat ID not found')
                                ->body('The customer needs to link their Telegram account first.')
                                ->warning()
                                ->send();

                            return;
                        }

                        $itemsList = "";
                        foreach ($record->order->items as $item) {
                            $bookName = $item->book?->title ?? 'Unknown Product';
                            $itemsList .= "• {$bookName} (x{$item->quantity}) - Rp " . number_format((float) $item->unit_price, 2, ',', '.') . "\n";
                        }

                        $message = "🔔 *New Invoice Available*\n\n" .
                            "*Invoice No:* {$record->invoice_no}\n" .
                            "--------------------------------\n" .
                            "*Items:*\n{$itemsList}" .
                            "--------------------------------\n" .
                            "*Grand Total:* Rp " . number_format((float) $record->grand_total, 2, ',', '.') . "\n\n" .
                            "Thank you for your order!";

                        $success = $telegramService->sendMessage($chatId, $message);

                        if ($success) {
                            \Filament\Notifications\Notification::make()
                                ->title('Invoice sent via Telegram')
                                ->success()
                                ->send();
                        } else {
                            \Filament\Notifications\Notification::make()
                                ->title('Failed to send Telegram message')
                                ->danger()
                                ->send();
                        }
                    })
                    ->visible(fn (Invoice $record): bool => ! empty($record->order?->user?->telegram_chat_id)),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }
}
