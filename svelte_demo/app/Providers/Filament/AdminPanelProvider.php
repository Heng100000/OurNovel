<?php
namespace App\Providers\Filament;

use Filament\Http\Middleware\Authenticate;
use Filament\Http\Middleware\AuthenticateSession;
use Filament\Http\Middleware\DisableBladeIconComponents;
use Filament\Http\Middleware\DispatchServingFilamentEvent;
use Filament\Pages\Dashboard;
use Filament\Panel;
use Filament\PanelProvider;
use Filament\Support\Colors\Color;
use Filament\Widgets\AccountWidget;
use Filament\Widgets\FilamentInfoWidget;
use Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse;
use Illuminate\Cookie\Middleware\EncryptCookies;
use Illuminate\Foundation\Http\Middleware\VerifyCsrfToken;
use Illuminate\Routing\Middleware\SubstituteBindings;
use Illuminate\Session\Middleware\StartSession;
use Illuminate\View\Middleware\ShareErrorsFromSession;
use Filament\Support\Enums\Width;
use Filament\View\PanelsRenderHook;
use Illuminate\Support\Facades\Blade;

use Filament\Support\Facades\FilamentView;
use Filament\Support\Facades\FilamentAsset;
use Filament\Support\Assets\Css;
use Illuminate\Support\HtmlString;

class AdminPanelProvider extends PanelProvider
{
    public function panel(Panel $panel): Panel
    {
        return $panel
            ->default()
            ->id('admin')
            ->path('admin')
            ->login()
            ->colors([
                'primary' => Color::hex('#0f7a47'),
            ])
            ->brandLogo(asset('images/logo_full.png'))
            ->brandLogoHeight('2.7rem')
            ->maxContentWidth(Width::Full)
            ->sidebarFullyCollapsibleOnDesktop()
            ->sidebarWidth('18rem')
            ->databaseNotifications()
            ->databaseNotificationsPolling('30s')
            ->globalSearch(position: \Filament\Enums\GlobalSearchPosition::Topbar)
            ->discoverResources(in: app_path('Filament/Resources'), for: 'App\Filament\Resources')
            ->discoverPages(in: app_path('Filament/Pages'), for: 'App\Filament\Pages')
            ->pages([
                Dashboard::class,
            ])
            ->discoverWidgets(in: app_path('Filament/Widgets'), for: 'App\Filament\Widgets')
            ->widgets([
                \App\Filament\Widgets\StatsOverview::class,
                \App\Filament\Widgets\DailySalesChart::class,
                \App\Filament\Widgets\RevenueChart::class,
                \App\Filament\Widgets\PaymentStatusChart::class,
                \App\Filament\Widgets\LatestOrders::class,
            ])
            ->middleware([
                EncryptCookies::class,
                AddQueuedCookiesToResponse::class,
                StartSession::class,
                AuthenticateSession::class,
                ShareErrorsFromSession::class,
                VerifyCsrfToken::class,
                SubstituteBindings::class,
                DisableBladeIconComponents::class,
                DispatchServingFilamentEvent::class,
            ])
            ->authMiddleware([
                Authenticate::class,
            ]);
    }

    public function boot(): void
    {
        FilamentView::registerRenderHook(
            PanelsRenderHook::HEAD_END,
            fn (): string => Blade::render('
                <script>
                    // Suppress known browser extension error "message channel closed"
                    window.addEventListener("error", (event) => {
                        if (event.message && event.message.includes("message channel closed")) {
                            event.stopImmediatePropagation();
                        }
                    });
                    window.addEventListener("unhandledrejection", (event) => {
                        if (event.reason && event.reason.message && event.reason.message.includes("message channel closed")) {
                            event.stopImmediatePropagation();
                            event.preventDefault();
                        }
                    });
                </script>
                <style>
                    /* Basic inline styles to prevent pop-in */
                    .fi-sidebar-item.fi-active .fi-sidebar-item-btn,
                    .fi-tabs-item.fi-active,
                    .fi-ac-btn-action {
                        background-color: #0f7a47 !important;
                        color: #ffffff !important;
                    }
                </style>
                @vite(\'resources/css/filament/theme.css\')
            '),
        );

        FilamentView::registerRenderHook(
            PanelsRenderHook::SIDEBAR_START,
            fn (): string => Blade::render('
                <div class="fi-sidebar-filter-ctn">
                    <div 
                        x-data="{ 
                            search: \'\',
                            applyFilter() {
                                let searchLower = this.search.toLowerCase();
                                this.$el.closest(\'.fi-sidebar\').querySelectorAll(\'.fi-sidebar-group\').forEach(group => {
                                    let hasVisibleItems = false;
                                    group.querySelectorAll(\'.fi-sidebar-item\').forEach(item => {
                                        let text = item.textContent.toLowerCase();
                                        let isMatch = text.includes(searchLower);
                                        item.style.display = isMatch ? \'\' : \'none\';
                                        if (isMatch) hasVisibleItems = true;
                                    });
                                    group.style.display = hasVisibleItems ? \'\' : \'none\';
                                });
                            }
                        }" 
                        class="fi-sidebar-filter-wrapper"
                    >
                        <label for="fi-sidebar-filter-input" class="fi-sr-only">
                            Search menu items
                        </label>
                        <input 
                            id="fi-sidebar-filter-input"
                            x-model="search"
                            x-on:input="applyFilter()"
                            type="text"
                            placeholder="Find menu items..."
                            class="fi-sidebar-filter"
                        >
                        <div class="fi-sidebar-filter-icon">
                            <x-filament::icon icon="heroicon-m-magnifying-glass" class="h-4 w-4" />
                        </div>
                        <div 
                            x-show="search.length > 0" 
                            x-cloak
                            class="fi-sidebar-filter-clear"
                            x-on:click="search = \'\'; applyFilter()"
                        >
                            <x-filament::icon icon="heroicon-m-x-mark" class="h-3 w-3" />
                        </div>
                    </div>
                </div>
            '),
        );
    }
}