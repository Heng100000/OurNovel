<?php

namespace App\Models;

use App\Traits\HasOptimizedImages;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BookImage extends Model
{
    /** @use HasFactory<\Database\Factories\BookImageFactory> */
    use HasFactory, HasOptimizedImages;

    public $timestamps = false;

    protected $fillable = [
        'book_id',
        'image_url',
        'is_primary',
    ];

    protected function casts(): array
    {
        return [
            'is_primary' => 'boolean',
        ];
    }

    public function book(): BelongsTo
    {
        return $this->belongsTo(Book::class);
    }
}
