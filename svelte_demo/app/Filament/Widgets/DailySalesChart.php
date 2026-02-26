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
        $days = collect(range(6, 0))->map(function ($day) {
            $date = now()->subDays($day);
            
            $revenue = \App\Models\Payment::whereDate('created_at', $date)
                ->where('status', 'paid')
                ->sum('amount');
                
            return [
                'label' => $date->format('D, M j'),
                'revenue' => (float) $revenue,
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
