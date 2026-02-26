<?php

namespace App\Filament\Resources\NewsAnnouncements\Schemas;

use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\RichEditor;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Schema;

class NewsAnnouncementForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('title')
                    ->required()
                    ->maxLength(255),
                FileUpload::make('image_url')
                    ->image()
                    ->directory('news-announcements')
                    ->label('Image'),
                RichEditor::make('description')
                    ->required()
                    ->columnSpanFull(),
            ]);
    }
}
