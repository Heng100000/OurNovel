<?php

namespace App\Filament\Widgets;

use Filament\Widgets\ChartWidget;

class DailySalesChart extends ChartWidget
{
    protected static ?int $sort = 2;

    protected int|string|array $columnSpan = 'full';

    protected ?string $heading = 'Daily Sales Trend';

    protected ?string $maxHeight = '225px';

    protected function getData(): array
    {
        $startDate = now()->subDays(6)->startOfDay();

        // Optimized: Fetch all revenue for the last 7 days in ONE query
        $revenueData = \App\Models\Payment::where('status', 'paid')
            ->where('created_at', '>=', $startDate)
            ->selectRaw('DATE(created_at) as date, SUM(amount) as revenue')
            ->groupBy('date')
            ->pluck('revenue', 'date');

        $days = collect(range(6, 0))->map(function ($day) use ($revenueData) {
            $date = now()->subDays($day);
            $dateString = $date->format('Y-m-d');

            return [
                'label' => $date->format('D, M j'),
                'revenue' => (float) $revenueData->get($dateString, 0),
            ];
        });

        return [
            'datasets' => [
                [
                    'label' => 'Daily Sales ($)',
                    'data' => $days->pluck('revenue')->toArray(),
                    'fill' => 'start',
                    'backgroundColor' => 'rgba(15, 122, 71, 0.1)',
                    'borderColor' => '#0f7a47',
                    'tension' => 0.4,
                ],
            ],
            'labels' => $days->pluck('label')->toArray(),
        ];
    }

    protected function getType(): string
    {
        return 'line';
    }

    protected function getOptions(): array
    {
        return [
            'plugins' => [
                'legend' => [
                    'display' => false,
                ],
            ],
            'scales' => [
                'y' => [
                    'grid' => [
                        'display' => false,
                    ],
                    'ticks' => [
                        'display' => false,
                    ],
                ],
                'x' => [
                    'grid' => [
                        'display' => false,
                    ],
                ],
            ],
            'elements' => [
                'line' => [
                    'borderWidth' => 3,
                    'capStyle' => 'round',
                ],
                'point' => [
                    'radius' => 0,
                    'hitRadius' => 10,
                ],
            ],
        ];
    }
}
