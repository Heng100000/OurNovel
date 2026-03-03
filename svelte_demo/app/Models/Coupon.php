<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Coupon extends Model
{
    /** @use HasFactory<\Database\Factories\CouponFactory> */
    use HasFactory;

    protected $fillable = [
        'code',
        'type',
        'amount',
        'min_spend',
        'valid_from',
        'valid_until',
        'usage_limit',
        'used_count',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'type' => 'string',
            'amount' => 'decimal:2',
            'min_spend' => 'decimal:2',
            'valid_from' => 'datetime',
            'valid_until' => 'datetime',
            'usage_limit' => 'integer',
            'used_count' => 'integer',
            'is_active' => 'boolean',
        ];
    }

    public function isValid(?float $subtotal = null): bool
    {
        $now = now();
        file_put_contents(storage_path('logs/diag.txt'), "Coupon::isValid called for {$this->code} with subtotal: {$subtotal} at {$now}\n", FILE_APPEND);
        \Illuminate\Support\Facades\Log::emergency("Coupon::isValid called for {$this->code} with subtotal: {$subtotal}. Server Time: {$now}");

        if (!$this->is_active) {
            \Illuminate\Support\Facades\Log::emergency("Coupon {$this->code} failed: not active. Server Time: {$now}");
            return false;
        }

        if ($this->usage_limit !== null && $this->used_count >= $this->usage_limit) {
            \Illuminate\Support\Facades\Log::emergency("Coupon {$this->code} failed: usage limit reached ({$this->used_count} / {$this->usage_limit}). Server Time: {$now}");
            return false;
        }

        if ($this->valid_from !== null && $this->valid_from->isFuture()) {
            \Illuminate\Support\Facades\Log::emergency("Coupon {$this->code} failed: valid_from in future ({$this->valid_from}). Server Time: {$now}");
            return false;
        }

        if ($this->valid_until !== null && $this->valid_until->isPast()) {
            \Illuminate\Support\Facades\Log::emergency("Coupon {$this->code} failed: valid_until in past ({$this->valid_until}). Server Time: {$now}");
            return false;
        }

        if ($subtotal !== null && $this->min_spend !== null && $subtotal < (float)$this->min_spend) {
            \Illuminate\Support\Facades\Log::emergency("Coupon {$this->code} failed: subtotal $subtotal < min_spend {$this->min_spend}. Server Time: {$now}");
            return false;
        }

        return true;
    }

    public function calculateDiscount(float $subtotal): float
    {
        if (!$this->isValid($subtotal)) {
            return 0.00;
        }

        if ($this->type === 'percentage') {
            $discount = $subtotal * ((float)$this->amount / 100);
            return min($discount, $subtotal); // Don't discount more than the order subtotal
        }

        // Fixed amount
        return min((float)$this->amount, $subtotal);
    }
}
