<?php

namespace App\Filament\Resources\Banners\Schemas;

use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Components\Utilities\Get;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class BannerForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Banner Content')
                    ->description('The main content that is visible on the banner.')
                    ->icon('heroicon-o-photo')
                    ->columns(2)
                    ->schema([
                        TextInput::make('title')
                            ->label('Title')
                            ->placeholder('e.g. Flash Sale')
                            ->columnSpanFull(),

                        TextInput::make('subtitle')
                            ->label('Subtitle / Badge Text')
                            ->placeholder('e.g. LIMITED TIME OFFER')
                            ->helperText('Shown as a small badge on the banner.'),

                        TextInput::make('discount_percentage')
                            ->label('Discount (%)')
                            ->numeric()
                            ->minValue(0)
                            ->maxValue(100)
                            ->suffix('%')
                            ->placeholder('e.g. 50'),

                        Textarea::make('description')
                            ->label('Description')
                            ->placeholder('Short promotional text or news...')
                            ->rows(3)
                            ->columnSpanFull(),

                        TextInput::make('button_text')
                            ->label('Button Label')
                            ->placeholder('e.g. Shop Now →')
                            ->helperText('Text shown on the call-to-action button.'),

                        FileUpload::make('image_url')
                            ->label('Banner Image')
                            ->image()
                            ->imagePreviewHeight('150')
                            ->acceptedFileTypes(['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/svg+xml'])
                            ->required()
                            ->columnSpanFull(),
                    ]),

                Section::make('Click Action')
                    ->description('Where should the user go when they tap this banner?')
                    ->icon('heroicon-o-cursor-arrow-rays')
                    ->columns(2)
                    ->schema([
                        Select::make('action_type')
                            ->label('Action Type')
                            ->options([
                                'none' => '— No Action —',
                                'book' => '📖 Book',
                                'category' => '📂 Category',
                                'promotion' => '🏷️ Promotion',
                                'url' => '🔗 External URL',
                            ])
                            ->required()
                            ->default('none')
                            ->live()
                            ->columnSpanFull(),

                        Select::make('action_id')
                            ->label('Select Item')
                            ->placeholder('Search and select...')
                            ->searchable()
                            ->getSearchResultsUsing(function (string $search, Get $get): array {
                                $type = $get('action_type');

                                return match ($type) {
                                    'book' => \App\Models\Book::query()
                                        ->where('title', 'like', "%{$search}%")
                                        ->limit(10)
                                        ->pluck('title', 'id')
                                        ->toArray(),
                                    'category' => \App\Models\Category::query()
                                        ->where('name', 'like', "%{$search}%")
                                        ->limit(10)
                                        ->pluck('name', 'id')
                                        ->toArray(),
                                    'promotion' => \App\Models\Promotion::query()
                                        ->where('event_name', 'like', "%{$search}%")
                                        ->limit(10)
                                        ->pluck('event_name', 'id')
                                        ->toArray(),
                                    default => [],
                                };
                            })
                            ->getOptionLabelUsing(function ($value, Get $get): ?string {
                                $type = $get('action_type');

                                return match ($type) {
                                    'book' => \App\Models\Book::find($value)?->title,
                                    'category' => \App\Models\Category::find($value)?->name,
                                    'promotion' => \App\Models\Promotion::find($value)?->event_name,
                                    default => null,
                                };
                            })
                            ->helperText('Search by name to find the item.')
                            ->visible(fn (Get $get) => in_array($get('action_type'), ['book', 'category', 'promotion'])),

                        TextInput::make('action_url')
                            ->label('External URL')
                            ->url()
                            ->placeholder('https://...')
                            ->columnSpanFull()
                            ->visible(fn (Get $get) => $get('action_type') === 'url'),
                    ]),

                Section::make('Scheduling & Visibility')
                    ->description('Control when this banner is shown to users.')
                    ->icon('heroicon-o-calendar-days')
                    ->columns(2)
                    ->schema([
                        Select::make('status')
                            ->label('Status')
                            ->options([
                                'active' => 'Active',
                                'inactive' => 'Inactive',
                            ])
                            ->required()
                            ->default('active'),

                        TextInput::make('display_order')
                            ->label('Display Order')
                            ->required()
                            ->numeric()
                            ->default(0)
                            ->helperText('Lower numbers appear first.'),

                        DateTimePicker::make('start_date')
                            ->label('Start Date')
                            ->placeholder('Leave empty to show immediately'),

                        DateTimePicker::make('end_date')
                            ->label('End Date')
                            ->placeholder('Leave empty to show indefinitely'),
                    ]),
            ]);
    }
}
