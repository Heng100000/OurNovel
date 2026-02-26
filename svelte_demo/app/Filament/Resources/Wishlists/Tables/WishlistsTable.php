<?php

namespace App\Filament\Resources\Wishlists\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Actions\BulkAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use App\Models\CartItem;
use Filament\Notifications\Notification;
use Illuminate\Database\Eloquent\Collection;

class WishlistsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('user.name')
                    ->label('Name')
                    ->searchable(),
                TextColumn::make('user.email')
                    ->label('Email')
                    ->searchable(),
                TextColumn::make('book.title')
                    ->label('Title')
                    ->searchable(),
                TextColumn::make('book.isbn')
                    ->label('ISBN')
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
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                    BulkAction::make('addToCart')
                        ->label('Add to Cart')
                        ->icon('heroicon-o-shopping-cart')
                        ->action(function (Collection $records) {
                            $addedCount = 0;
                            $skippedCount = 0;

                            foreach ($records as $record) {
                                $book = $record->book;

                                if ($book && $book->stock_qty > 0) {
                                    $cartItem = CartItem::where('user_id', $record->user_id)
                                        ->where('book_id', $record->book_id)
                                        ->first();

                                    if ($cartItem) {
                                        $cartItem->increment('quantity');
                                    } else {
                                        CartItem::create([
                                            'user_id' => $record->user_id,
                                            'book_id' => $record->book_id,
                                            'quantity' => 1,
                                        ]);
                                    }
                                    $addedCount++;
                                } else {
                                    $skippedCount++;
                                }
                            }

                            $notification = Notification::make();

                            if ($addedCount > 0) {
                                $notification->success()
                                    ->title('Added to Cart')
                                    ->body("Successfully added {$addedCount} items to cart" . ($skippedCount > 0 ? ", while {$skippedCount} were skipped due to stock issues." : "."));
                            } else {
                                $notification->warning()
                                    ->title('Could Not Add to Cart')
                                    ->body("Selected items could not be added because they are out of stock.");
                            }

                            $notification->send();
                        })
                        ->deselectRecordsAfterCompletion(),
                ]),
            ]);
    }
}
