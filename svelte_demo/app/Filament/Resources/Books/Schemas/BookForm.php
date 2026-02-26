<?php

namespace App\Filament\Resources\Books\Schemas;

use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Repeater;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Forms\Components\Placeholder;
use Filament\Schemas\Components\Utilities\Get;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Components\Tabs;
use Filament\Schemas\Components\Tabs\Tab;
use Filament\Schemas\Schema;
use App\Models\Promotion;

class BookForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Tabs::make('Book Details')
                    ->columnSpanFull()
                    ->tabs([

                        Tab::make('General')
                            ->icon('heroicon-o-book-open')
                            ->schema([
                                Section::make('Book Identity')
                                    ->description('Core information about the book — make it searchable and clear.')
                                    ->icon('heroicon-o-information-circle')
                                    ->columns(2)
                                    ->schema([
                                        TextInput::make('title')
                                            ->label('Book Title')
                                            ->placeholder('e.g. The Great Gatsby')
                                            ->required()
                                            ->maxLength(255)
                                            ->columnSpanFull(),
                                        TextInput::make('isbn')
                                            ->label('ISBN')
                                            ->placeholder('e.g. 978-3-16-148410-0')
                                            ->maxLength(20)
                                            ->helperText('International Standard Book Number — leave blank if not available.'),
                                        Select::make('author_id')
                                            ->label('Author')
                                            ->relationship('author', 'name')
                                            ->searchable()
                                            ->preload()
                                            ->required()
                                            ->helperText('Search and select the book\'s author.'),
                                        Select::make('category_id')
                                            ->label('Category')
                                            ->relationship('category', 'name')
                                            ->searchable()
                                            ->preload()
                                            ->required(),
                                        Select::make('promotion_id')
                                            ->label('Promotion')
                                            ->relationship('promotion', 'event_name')
                                            ->searchable()
                                            ->preload()
                                            ->live()
                                            ->helperText('Optionally link to an active promotion.'),
                                        Placeholder::make('discounted_price')
                                            ->label('Discounted Price')
                                            ->content(function (Get $get) {
                                                $price = (float) $get('price');
                                                $promotionId = $get('promotion_id');

                                                if (! $price || ! $promotionId) {
                                                    return '-';
                                                }

                                                $promotion = Promotion::find($promotionId);
                                                
                                                if (! $promotion || $promotion->status !== 'active') {
                                                    return '-';
                                                }

                                                $now = now();
                                                if ($promotion->start_date && $now->lt($promotion->start_date->startOfDay())) {
                                                    return 'Starts ' . $promotion->start_date->format('M d');
                                                }
                                                if ($promotion->end_date && $now->gt($promotion->end_date->endOfDay())) {
                                                    return 'Expired';
                                                }

                                                if ($promotion->discount_type === 'percentage') {
                                                    $discount = $price * ($promotion->discount_value / 100);
                                                    return '$' . number_format($price - $discount, 2);
                                                }

                                                if ($promotion->discount_type === 'fixed') {
                                                    return '$' . number_format(max(0, $price - $promotion->discount_value), 2);
                                                }

                                                return '-';
                                            }),
                                        Textarea::make('description')
                                            ->label('Description')
                                            ->placeholder('Describe the book, its themes, and what makes it special...')
                                            ->rows(5)
                                            ->required()
                                            ->columnSpanFull(),
                                    ]),
                            ]),

                        Tab::make('Pricing & Stock')
                            ->icon('heroicon-o-currency-dollar')
                            ->schema([
                                Section::make('Pricing & Availability')
                                    ->description('Set the price, inventory level, and the visibility of this book in your store.')
                                    ->icon('heroicon-o-chart-bar')
                                    ->columns(3)
                                    ->schema([
                                        TextInput::make('price')
                                            ->label('Price')
                                            ->required()
                                            ->numeric()
                                            ->prefix('$')
                                            ->minValue(0)
                                            ->live(onBlur: true)
                                            ->placeholder('0.00'),
                                        TextInput::make('stock_qty')
                                            ->label('Stock Quantity')
                                            ->required()
                                            ->numeric()
                                            ->default(1)
                                            ->minValue(0)
                                            ->suffix('units')
                                            ->helperText('Set to 0 to mark as out of stock.'),
                                        TextInput::make('warning_qty')
                                            ->label('Low Stock Warning')
                                            ->numeric()
                                            ->default(0)
                                            ->minValue(0)
                                            ->suffix('units')
                                            ->helperText('Trigger warning notification when stock reaches this level.'),
                                        Select::make('condition')
                                            ->label('Condition')
                                            ->options([
                                                'New' => 'New',
                                                'Popular' => 'Popular',
                                            ])
                                            ->nullable()
                                            ->native(false),
                                        Select::make('status')
                                            ->label('Listing Status')
                                            ->options([
                                                'active' => 'Active',
                                                'inactive' => 'Inactive',
                                                'out_of_stock' => 'Out of Stock',
                                            ])
                                            ->required()
                                            ->default('active')
                                            ->native(false),
                                        FileUpload::make('video_url')
                                            ->label('Preview Video')
                                            ->directory('flutter-book/videos')
                                            ->acceptedFileTypes(['video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/x-flv', 'video/webm'])
                                            ->maxSize(51200) // 50MB max
                                            ->helperText('Upload a video walkthrough or trailer (Max 50MB).')
                                            ->columnSpan(2),
                                    ]),
                            ]),

                        Tab::make('Images')
                            ->icon('heroicon-o-photo')
                            ->schema([
                                Section::make('Book Gallery')
                                    ->description('Add your book cover and additional gallery images. Toggle to mark the primary cover.')
                                    ->icon('heroicon-o-camera')
                                    ->schema([
                                        Repeater::make('images')
                                            ->relationship('images')
                                            ->label(false)
                                            ->schema([
                                                FileUpload::make('image_url')
                                                    ->label('Image')
                                                    ->image()
                                                    ->imageEditor()
                                                    ->directory('flutter-book')
                                                    ->imagePreviewHeight('200')
                                                    ->loadingIndicatorPosition('left')
                                                    ->panelAspectRatio('4:3')
                                                    ->panelLayout('integrated')
                                                    ->removeUploadedFileButtonPosition('right')
                                                    ->uploadButtonPosition('left')
                                                    ->uploadProgressIndicatorPosition('left')
                                                    ->required(),
                                                Toggle::make('is_primary')
                                                    ->label('Primary Cover')
                                                    ->default(false)
                                                    ->onColor('warning')
                                                    ->offColor('gray'),
                                            ])
                                            ->grid(3)
                                            ->itemLabel(fn (array $state): ?string => $state['is_primary'] ? 'Primary Cover' : 'Gallery Image')
                                            ->collapsible()
                                            ->addActionLabel('Add Another Image')
                                            ->defaultItems(1),
                                    ]),
                            ]),
                    ]),
            ]);
    }
}
