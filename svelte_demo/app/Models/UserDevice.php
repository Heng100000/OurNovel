<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserDevice extends Model
{
    /** @use HasFactory<\Database\Factories\UserDeviceFactory> */
    use HasFactory;

    public $timestamps = false; // created_at exists but no updated_at per schema

    protected $fillable = [
        'user_id',
        'fcm_token',
        'device_type',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
