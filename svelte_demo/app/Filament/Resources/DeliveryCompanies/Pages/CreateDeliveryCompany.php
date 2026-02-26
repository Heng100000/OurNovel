<?php

namespace App\Filament\Resources\DeliveryCompanies\Pages;

use App\Filament\Resources\DeliveryCompanies\DeliveryCompanyResource;
use Filament\Resources\Pages\CreateRecord;
use Filament\Support\Enums\Width;

class CreateDeliveryCompany extends CreateRecord
{
    protected static string $resource = DeliveryCompanyResource::class;

    public function getMaxContentWidth(): Width | string | null
    {
        return Width::Full;
    }
}
