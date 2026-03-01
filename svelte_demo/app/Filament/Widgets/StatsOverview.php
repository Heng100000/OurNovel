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
        $startDate = now()->subDays(6)->startOfDay();

        // Optimized: Fetch all paid payments for the last 7 days in ONE query
        $payments = \App\Models\Payment::where('status', 'paid')
            ->where('created_at', '>=', $startDate)
            ->selectRaw('DATE(created_at) as date, SUM(amount) as total')
            ->groupBy('date')
            ->pluck('total', 'date');

        // Optimized: Fetch all new customers for the last 7 days in ONE query
        $customers = \App\Models\User::where('role', 'customer')
            ->where('created_at', '>=', $startDate)
            ->selectRaw('DATE(created_at) as date, COUNT(*) as count')
            ->groupBy('date')
            ->pluck('count', 'date');

        // Fill in missing days with 0 to ensure the chart has 7 points
        $paymentChart = [];
        $userChart = [];
        for ($i = 6; $i >= 0; $i--) {
            $date = now()->subDays($i)->format('Y-m-d');
            $paymentChart[] = $payments->get($date, 0);
            $userChart[] = $customers->get($date, 0);
        }

        // Consolidated counts
        $paymentCounts = \App\Models\Payment::selectRaw("
            SUM(CASE WHEN status = 'paid' THEN amount ELSE 0 END) as total_revenue,
            COUNT(CASE WHEN status = 'paid' THEN 1 END) as paid_count,
            COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_count
        ")->first();

        $totalCustomers = \App\Models\User::where('role', 'customer')->count();

        return [
            Stat::make('Total Revenue', '$'.number_format($paymentCounts->total_revenue ?? 0, 2))
                ->description('Total paid earnings')
                ->descriptionIcon('heroicon-m-arrow-trending-up')
                ->chart($paymentChart)
                ->color('success'),

            Stat::make('Pending Payments', $paymentCounts->pending_count ?? 0)
                ->description(($paymentCounts->pending_count ?? 0) > 0 ? 'Action required' : 'All clear')
                ->descriptionIcon(($paymentCounts->pending_count ?? 0) > 0 ? 'heroicon-m-exclamation-circle' : 'heroicon-m-check-badge')
                ->color(($paymentCounts->pending_count ?? 0) > 0 ? 'warning' : 'gray'),

            Stat::make('Successful Payments', $paymentCounts->paid_count ?? 0)
                ->description('Completed transactions')
                ->descriptionIcon('heroicon-m-check-circle')
                ->color('success'),

            Stat::make('New Customers', $totalCustomers)
                ->description('Total customer base')
                ->descriptionIcon('heroicon-m-user-group')
                ->chart($userChart)
                ->color('info'),
        ];
    }
}
