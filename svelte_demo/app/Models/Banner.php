<?php

namespace App\Models;

use App\Traits\HasOptimizedImages;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Banner extends Model
{
    /** @use HasFactory<\Database\Factories\BannerFactory> */
    use HasFactory, HasOptimizedImages;

    protected $fillable = [
        'title',
        'subtitle',
        'description',
        'image_url',
        'discount_percentage',
        'button_text',
        'action_type',
        'action_id',
        'action_url',
        'display_order',
        'status',
        'start_date',
        'end_date',
    ];

    protected function casts(): array
    {
        return [
            'display_order' => 'integer',
            'start_date' => 'datetime',
            'end_date' => 'datetime',
        ];
    }
}
