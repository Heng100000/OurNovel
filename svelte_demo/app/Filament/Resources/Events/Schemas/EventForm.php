<?php

namespace App\Filament\Resources\Events\Schemas;

use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\RichEditor;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class EventForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                // ── General Info ─────────────────────────────────────────
                Section::make('General Information')
                    ->description('Set the event title, banner, description, and visibility.')
                    ->icon('heroicon-o-information-circle')
                    ->schema([
                        FileUpload::make('banner_image_path')
                            ->label('Event Banner')
                            ->image()
                            ->disk('public')
                            ->directory('events/banners')
                            ->imageEditor()
                            ->imageEditorAspectRatios(['16:9', '4:3'])
                            ->columnSpanFull(),

                        TextInput::make('title')
                            ->label('Event Title')
                            ->placeholder('e.g. Summer Book Fair 2026')
                            ->required()
                            ->maxLength(255)
                            ->columnSpanFull(),

                        RichEditor::make('description')
                            ->label('Event Description')
                            ->placeholder('Describe what this event is about...')
                            ->toolbarButtons([
                                'bold', 'italic', 'underline', 'strike',
                                'bulletList', 'orderedList', 'link', 'blockquote',
                            ])
                            ->columnSpanFull(),

                        Toggle::make('is_active')
                            ->label('Visible to Customers')
                            ->helperText('Switch on to make this event publicly visible.')
                            ->onColor('success')
                            ->default(true),
                    ]),

                // ── Schedule ─────────────────────────────────────────────
                Section::make('Schedule')
                    ->description('Define when the event starts and ends. The event will only be visible to customers within this date range.')
                    ->icon('heroicon-o-calendar-days')
                    ->schema([
                        Grid::make(2)
                            ->schema([
                                DateTimePicker::make('start_date')
                                    ->label('Start Date & Time')
                                    ->helperText('When does the event open?')
                                    ->hint('Inclusive')
                                    ->hintIcon('heroicon-m-information-circle')
                                    ->native(false)
                                    ->prefixIcon('heroicon-o-arrow-right-circle')
                                    ->displayFormat('M d, Y h:i A')
                                    ->seconds(false),

                                DateTimePicker::make('end_date')
                                    ->label('End Date & Time')
                                    ->helperText('When does the event close?')
                                    ->hint('Inclusive')
                                    ->hintIcon('heroicon-m-information-circle')
                                    ->native(false)
                                    ->prefixIcon('heroicon-o-x-circle')
                                    ->displayFormat('M d, Y h:i A')
                                    ->seconds(false)
                                    ->after('start_date'),
                            ]),
                    ]),
            ]);
    }
}
