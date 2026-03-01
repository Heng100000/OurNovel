<?php

namespace App\Filament\Resources\Users\Schemas;

use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;
use Spatie\Permission\Models\Role;

class UserForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([

                Section::make('Identity')
                    ->description('Basic profile information for this user.')
                    ->icon('heroicon-o-user-circle')
                    ->columns(2)
                    ->schema([
                        TextInput::make('name')
                            ->label('Full Name')
                            ->placeholder('e.g. John Doe')
                            ->prefixIcon('heroicon-m-user')
                            ->required()
                            ->maxLength(255),

                        TextInput::make('email')
                            ->label('Email Address')
                            ->placeholder('e.g. john@example.com')
                            ->prefixIcon('heroicon-m-envelope')
                            ->email()
                            ->required()
                            ->unique(ignoreRecord: true)
                            ->maxLength(255),

                        TextInput::make('phone')
                            ->label('Phone Number')
                            ->placeholder('+855 xx xxx xxx')
                            ->prefixIcon('heroicon-m-phone')
                            ->tel()
                            ->maxLength(20),

                        TextInput::make('telegram_chat_id')
                            ->label('Telegram Chat ID')
                            ->placeholder('e.g. 123456789')
                            ->prefixIcon('heroicon-m-chat-bubble-left-ellipsis')
                            ->helperText('Used for order notifications via Telegram Bot.')
                            ->maxLength(50),
                    ]),

                Section::make('Security')
                    ->description('Set or update the login password.')
                    ->icon('heroicon-o-lock-closed')
                    ->columns(1)
                    ->schema([
                        TextInput::make('password')
                            ->label('Password')
                            ->password()
                            ->revealable()
                            ->prefixIcon('heroicon-m-key')
                            ->placeholder('Leave blank to keep existing password')
                            ->required(fn ($livewire) => $livewire instanceof \Filament\Resources\Pages\CreateRecord)
                            ->dehydrated(fn ($state) => filled($state))
                            ->dehydrateStateUsing(fn ($state) => \Illuminate\Support\Facades\Hash::make($state))
                            ->maxLength(255)
                            ->helperText('Minimum 8 characters recommended.'),
                    ]),

                Section::make('Role & Access')
                    ->description('Control what this user can do in the system.')
                    ->icon('heroicon-o-shield-check')
                    ->columns(2)
                    ->schema([
                        Select::make('status')
                            ->label('Account Status')
                            ->prefixIcon('heroicon-m-signal')
                            ->options([
                                'active' => 'Active',
                                'banned' => 'Banned',
                            ])
                            ->required()
                            ->default('active')
                            ->native(false)
                            ->helperText('Banned users cannot log in.'),

                        Select::make('role')
                            ->label('App Role')
                            ->prefixIcon('heroicon-m-tag')
                            ->options([
                                'admin' => 'Admin',
                                'customer' => 'Customer',
                            ])
                            ->required()
                            ->default('customer')
                            ->native(false)
                            ->helperText('Determines API-level access for the mobile app.'),

                        Select::make('shield_roles')
                            ->label('Admin Panel Roles')
                            ->prefixIcon('heroicon-m-shield-exclamation')
                            ->options(fn () => Role::pluck('name', 'name')
                                ->map(fn ($name) => match ($name) {
                                    'super_admin' => '⭐ Super Admin — Full access',
                                    'admin' => '🛡️ Admin — Manage all resources',
                                    default => '👤 '.ucfirst($name),
                                })->toArray())
                            ->multiple()
                            ->searchable()
                            ->preload()
                            ->columnSpanFull()
                            ->helperText('Shield roles control permissions inside the admin panel.')
                            ->afterStateHydrated(function (Select $component, $record) {
                                if ($record) {
                                    $component->state($record->roles->pluck('name')->toArray());
                                }
                            })
                            ->saveRelationshipsUsing(function ($record, $state) {
                                if ($record) {
                                    $record->syncRoles($state ?? []);
                                }
                            })
                            ->dehydrated(false),
                    ]),

            ]);
    }
}
