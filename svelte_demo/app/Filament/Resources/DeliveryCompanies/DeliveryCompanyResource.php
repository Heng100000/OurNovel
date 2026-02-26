<?php

namespace App\Filament\Resources\DeliveryCompanies;

use App\Filament\Resources\DeliveryCompanies\Pages\CreateDeliveryCompany;
use App\Filament\Resources\DeliveryCompanies\Pages\EditDeliveryCompany;
use App\Filament\Resources\DeliveryCompanies\Pages\ListDeliveryCompanies;
use App\Filament\Resources\DeliveryCompanies\Schemas\DeliveryCompanyForm;
use App\Filament\Resources\DeliveryCompanies\Tables\DeliveryCompaniesTable;
use App\Models\DeliveryCompany;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class DeliveryCompanyResource extends Resource
{
    protected static ?string $model = DeliveryCompany::class;

    protected static string|BackedEnum|null $navigationIcon = 'heroicon-o-truck';

    protected static string|\UnitEnum|null $navigationGroup = 'Settings';

    protected static ?int $navigationSort = 1;

    protected static ?string $recordTitleAttribute = 'name';

    public static function form(Schema $schema): Schema
    {
        return DeliveryCompanyForm::configure($schema);
    }

    public static function table(Table $table): Table
    {
        return DeliveryCompaniesTable::configure($table);
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
            'index' => ListDeliveryCompanies::route('/'),
            'create' => CreateDeliveryCompany::route('/create'),
            'edit' => EditDeliveryCompany::route('/{record}/edit'),
        ];
    }
}
