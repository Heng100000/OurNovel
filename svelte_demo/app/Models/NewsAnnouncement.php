<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class NewsAnnouncement extends Model
{
    protected $fillable = [
        'title',
        'image_url',
        'description',
    ];
}