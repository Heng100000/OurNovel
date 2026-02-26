<?php

namespace App\Filament\Widgets;

use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class StatsOverview extends StatsOverviewWidget
{
    protected static ?int $sort = 1;

    protected ?string $pollingInterval = '15s';

    protected function getStats(): array
    {
        // Calculate charts (last 7 days)
        $paymentChart = collect(range(6, 0))->map(fn ($days) => 
            \App\Models\Payment::whereDate('created_at', now()->subDays($days))->where('status', 'paid')->sum('amount')
        )->toArray();

        $userChart = collect(range(6, 0))->map(fn ($days) => 
            \App\Models\User::whereDate('created_at', now()->subDays($days))->where('role', 'customer')->count()
        )->toArray();

        $paidCount = \App\Models\Payment::where('status', 'paid')->count();
        $pendingCount = \App\Models\Payment::where('status', 'pending')->count();

        return [
            Stat::make('Total Revenue', '$' . number_format(\App\Models\Payment::where('status', 'paid')->sum('amount'), 2))
                ->description('Total paid earnings')
                ->descriptionIcon('heroicon-m-arrow-trending-up')
                ->chart($paymentChart)
                ->color('success'),

            Stat::make('Pending Payments', $pendingCount)
                ->description($pendingCount > 0 ? 'Action required' : 'All clear')
                ->descriptionIcon($pendingCount > 0 ? 'heroicon-m-exclamation-circle' : 'heroicon-m-check-badge')
                ->color($pendingCount > 0 ? 'warning' : 'gray'),

            Stat::make('Successful Payments', $paidCount)
                ->description('Completed transactions')
                ->descriptionIcon('heroicon-m-check-circle')
                ->color('success'),

            Stat::make('New Customers', \App\Models\User::where('role', 'customer')->count())
                ->description('Total customer base')
                ->descriptionIcon('heroicon-m-user-group')
                ->chart($userChart)
                ->color('info'),
        ];
    }
}
