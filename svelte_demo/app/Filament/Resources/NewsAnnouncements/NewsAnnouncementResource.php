<?php

namespace App\Filament\Resources\NewsAnnouncements;

use App\Filament\Resources\NewsAnnouncements\Pages\CreateNewsAnnouncement;
use App\Filament\Resources\NewsAnnouncements\Pages\EditNewsAnnouncement;
use App\Filament\Resources\NewsAnnouncements\Pages\ListNewsAnnouncements;
use App\Filament\Resources\NewsAnnouncements\Schemas\NewsAnnouncementForm;
use App\Filament\Resources\NewsAnnouncements\Tables\NewsAnnouncementsTable;
use App\Models\NewsAnnouncement;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class NewsAnnouncementResource extends Resource
{
    protected static ?string $model = NewsAnnouncement::class;

    protected static string|\BackedEnum|null $navigationIcon = 'heroicon-o-megaphone';

    protected static string|\UnitEnum|null $navigationGroup = 'Communications';

    protected static ?int $navigationSort = 2;

    protected static ?string $navigationLabel = 'News Announcements';

    protected static ?string $pluralModelLabel = 'News Announcements';

    public static function form(Schema $schema): Schema
    {
        return NewsAnnouncementForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return NewsAnnouncementsTable::configure($table);
    }

    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListNewsAnnouncements::route('/'),
            'create' => CreateNewsAnnouncement::route('/create'),
            'edit' => EditNewsAnnouncement::route('/{record}/edit'),
        ];
    }
}
