<?php

namespace App\Models;

use App\Traits\HasOptimizedImages;
use Illuminate\Database\Eloquent\Model;

class NewsAnnouncement extends Model
{
    use HasOptimizedImages;

    protected $fillable = [
        'title',
        'news_type_id',
        'image_url',
        'description',
    ];

    public function newsType()
    {
        return $this->belongsTo(NewsType::class);
    }
}
