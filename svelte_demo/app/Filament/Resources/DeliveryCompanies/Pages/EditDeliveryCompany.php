<?php

namespace App\Filament\Resources\DeliveryCompanies\Pages;

use App\Filament\Resources\DeliveryCompanies\DeliveryCompanyResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;
use Filament\Support\Enums\Width;

class EditDeliveryCompany extends EditRecord
{
    protected static string $resource = DeliveryCompanyResource::class;

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make(),
        ];
    }

    public function getMaxContentWidth(): Width | string | null
    {
        return Width::Full;
    }
}
