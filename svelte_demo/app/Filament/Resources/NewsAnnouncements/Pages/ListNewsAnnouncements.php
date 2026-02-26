<?php

namespace App\Filament\Resources\NewsAnnouncements\Pages;

use App\Filament\Resources\NewsAnnouncements\NewsAnnouncementResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListNewsAnnouncements extends ListRecords
{
    protected static string $resource = NewsAnnouncementResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}
