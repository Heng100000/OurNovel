<?php

namespace App\Filament\Resources\NewsAnnouncements\Pages;

use App\Filament\Resources\NewsAnnouncements\NewsAnnouncementResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditNewsAnnouncement extends EditRecord
{
    protected static string $resource = NewsAnnouncementResource::class;

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make(),
        ];
    }
}
