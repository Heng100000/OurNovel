<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Book extends Model
{
    /** @use HasFactory<\Database\Factories\BookFactory> */
    use HasFactory;

    protected $fillable = [
        'category_id',
        'author_id',
        'promotion_id',
        'title',
        'isbn',
        'description',
        'price',
        'condition',
        'stock_qty',
        'warning_qty',
        'status',
        'video_url',
    ];

    protected function casts(): array
    {
        return [
            'id' => 'integer',
            'author_id' => 'integer',
            'category_id' => 'integer',
            'price' => 'decimal:2',
            'stock_qty' => 'integer',
            'warning_qty' => 'integer',
        ];
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function author(): BelongsTo
    {
        return $this->belongsTo(Author::class);
    }

    public function promotion(): BelongsTo
    {
        return $this->belongsTo(Promotion::class);
    }

    public function images(): HasMany
    {
        return $this->hasMany(BookImage::class);
    }

    public function primaryImage(): HasOne
    {
        return $this->hasOne(BookImage::class)->where('is_primary', true);
    }

    public function reviews(): HasMany
    {
        return $this->hasMany(Review::class);
    }

    public function getDiscountedPriceAttribute(): ?string
    {
        if (!$this->promotion || $this->promotion->status !== 'active') {
            return null;
        }

        $now = now();
        
        // If start_date is set, ensure we are at or after the start of that day
        if ($this->promotion->start_date && $now->lt($this->promotion->start_date->startOfDay())) {
            return null;
        }
        
        // If end_date is set, ensure we are at or before the end of that day
        if ($this->promotion->end_date && $now->gt($this->promotion->end_date->endOfDay())) {
            return null;
        }

        if ($this->promotion->discount_type === 'percentage') {
            $discount = $this->price * ($this->promotion->discount_value / 100);
            return number_format($this->price - $discount, 2, '.', '');
        }

        if ($this->promotion->discount_type === 'fixed') {
            return number_format(max(0, $this->price - $this->promotion->discount_value), 2, '.', '');
        }

        return null;
    }
}
