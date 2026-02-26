<?php

namespace App\Filament\Widgets;

use Filament\Widgets\ChartWidget;

class RevenueChart extends ChartWidget
{
    protected static ?int $sort = 3;

    protected ?string $heading = 'Monthly Revenue';
    
    protected ?string $maxHeight = '275px';

    protected function getData(): array
    {
        $currentYear = now()->year;
        
        $data = collect(range(1, 12))->map(function ($month) use ($currentYear) {
            return \App\Models\Payment::whereYear('created_at', $currentYear)
                ->whereMonth('created_at', $month)
                ->where('status', 'paid')
                ->sum('amount');
        })->toArray();

        return [
            'datasets' => [
                [
                    'label' => 'Revenue ($)',
                    'data' => $data,
                    'backgroundColor' => '#0f7a47',
                    'borderColor' => '#0f7a47',
                ],
            ],
            'labels' => ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
        ];
    }

    protected function getType(): string
    {
        return 'bar';
    }
}
