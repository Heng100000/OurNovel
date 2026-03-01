<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class NewsType extends Model
{
    protected $fillable = ['name'];

    public function newsAnnouncements()
    {
        return $this->hasMany(NewsAnnouncement::class);
    }
}
