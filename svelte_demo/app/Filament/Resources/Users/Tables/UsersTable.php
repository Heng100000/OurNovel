<?php

namespace App\Filament\Resources\Users\Tables;

use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\Action;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Textarea;
use App\Models\Notification;
use Filament\Notifications\Notification as FilamentNotification;

class UsersTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('name')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('email')
                    ->label('Email address')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('phone')
                    ->searchable(),
                TextColumn::make('role')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'admin' => 'danger',
                        'customer' => 'info',
                        default => 'gray',
                    })
                    ->searchable(),
                TextColumn::make('status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'active' => 'success',
                        'banned' => 'danger',
                        default => 'gray',
                    })
                    ->searchable(),
                TextColumn::make('telegram_chat_id')
                    ->label('Telegram')
                    ->badge()
                    ->getStateUsing(fn ($record) => $record->telegram_chat_id ? 'Linked' : 'Not Linked')
                    ->color(fn ($state) => $state === 'Linked' ? 'success' : 'warning')
                    ->copyable()
                    ->copyMessage('Bot link copied')
                    ->copyableState(fn (\App\Models\User $record) => "https://t.me/hengcode_bot?start={$record->id}")
                    ->tooltip('Click to copy linking URL'),
                TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                //
            ])
            ->recordActions([
                Action::make('sendPush')
                    ->label('Push')
                    ->icon('heroicon-o-paper-airplane')
                    ->color('info')
                    ->form([
                        TextInput::make('title')
                            ->required(),
                        Textarea::make('message')
                            ->required(),
                    ])
                    ->action(function (array $data, \App\Models\User $record) {
                        Notification::create([
                            'user_id' => $record->id,
                            'title' => $data['title'],
                            'message' => $data['message'],
                            'type' => 'manual_push',
                            'is_read' => false,
                        ]);

                        FilamentNotification::make()
                            ->title('Push notification sent')
                            ->success()
                            ->send();
                    }),
                EditAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }
}
