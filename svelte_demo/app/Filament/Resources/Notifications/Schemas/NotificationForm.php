<?php

namespace App\Filament\Resources\Notifications\Schemas;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Schema;

class NotificationForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('user_id')
                    ->relationship('user', 'name')
                    ->required(),
                TextInput::make('title')
                    ->required(),
                Textarea::make('message')
                    ->required()
                    ->helperText('This message will be sent as a push notification to all of the user\'s registered devices.')
                    ->columnSpanFull(),
                TextInput::make('type'),
                Toggle::make('is_read')
                    ->required(),
            ]);
    }
}
