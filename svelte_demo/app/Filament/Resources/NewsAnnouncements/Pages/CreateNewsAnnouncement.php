<?php

namespace App\Filament\Resources\NewsAnnouncements\Pages;

use App\Filament\Resources\NewsAnnouncements\NewsAnnouncementResource;
use Filament\Resources\Pages\CreateRecord;

class CreateNewsAnnouncement extends CreateRecord
{
    protected static string $resource = NewsAnnouncementResource::class;
}
