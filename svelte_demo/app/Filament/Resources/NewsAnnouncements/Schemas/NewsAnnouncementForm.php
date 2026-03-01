<?php

namespace App\Filament\Resources\NewsAnnouncements\Schemas;

use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\RichEditor;
use Filament\Forms\Components\Select;
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
                Select::make('news_type_id')
                    ->relationship('newsType', 'name')
                    ->required(),
                FileUpload::make('image_url')
                    ->acceptedFileTypes(['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/svg+xml'])
                    ->directory('news-announcements')
                    ->label('Image'),
                RichEditor::make('description')
                    ->required()
                    ->columnSpanFull(),
            ]);
    }
}
