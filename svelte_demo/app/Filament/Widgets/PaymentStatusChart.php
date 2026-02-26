<?php

namespace App\Filament\Widgets;

use Filament\Widgets\ChartWidget;

class PaymentStatusChart extends ChartWidget
{
    protected static ?int $sort = 4;

    protected ?string $heading = 'Payment Status Distribution';
    
    protected ?string $maxHeight = '275px';

    protected function getData(): array
    {
        $paidCount = \App\Models\Payment::where('status', 'paid')->count();
        $pendingCount = \App\Models\Payment::where('status', 'pending')->count();

        return [
            'datasets' => [
                [
                    'label' => 'Total Payments',
                    'data' => [$paidCount, $pendingCount],
                    'backgroundColor' => [
                        '#10b981', // green-500 for Paid
                        '#f59e0b', // amber-500 for Pending
                    ],
                ],
            ],
            'labels' => ['Paid', 'Pending'],
        ];
    }

    protected function getType(): string
    {
        return 'pie';
    }
}
