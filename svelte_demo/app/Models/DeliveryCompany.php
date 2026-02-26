<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class DeliveryCompany extends Model
{
    /** @use HasFactory<\Database\Factories\DeliveryCompanyFactory> */
    use HasFactory;

    protected $fillable = [
        'name',
        'logo_path',
        'contact_phone',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }

    public function shippingRates(): HasMany
    {
        return $this->hasMany(ShippingRate::class);
    }

    public function shippings(): HasMany
    {
        return $this->hasMany(Shipping::class);
    }
}
