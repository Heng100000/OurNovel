<?php

namespace App\Filament\Resources\DeliveryCompanies\Pages;

use App\Filament\Resources\DeliveryCompanies\DeliveryCompanyResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;
use Filament\Schemas\Components\Tabs\Tab;
use Illuminate\Database\Eloquent\Builder;

class ListDeliveryCompanies extends ListRecords
{
    protected static string $resource = DeliveryCompanyResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }

    public function getTabs(): array
    {
        return [
            'all' => Tab::make()
                ->icon('heroicon-m-list-bullet'),
            'active' => Tab::make()
                ->icon('heroicon-m-check-circle')
                ->modifyQueryUsing(fn (Builder $query) => $query->where('is_active', true))
                ->badge(static::getResource()::getModel()::query()->where('is_active', true)->count())
                ->badgeColor('success'),
            'inactive' => Tab::make()
                ->icon('heroicon-m-x-circle')
                ->modifyQueryUsing(fn (Builder $query) => $query->where('is_active', false))
                ->badge(static::getResource()::getModel()::query()->where('is_active', false)->count())
                ->badgeColor('danger'),
        ];
    }
}
