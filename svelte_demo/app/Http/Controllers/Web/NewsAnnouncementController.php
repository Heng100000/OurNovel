<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\NewsAnnouncement;
use Inertia\Inertia;
use Inertia\Response;

class NewsAnnouncementController extends Controller
{
    /**
     * Display the specified news announcement.
     */
    public function show(NewsAnnouncement $newsAnnouncement): Response
    {
        $newsAnnouncement->load('newsType');

        return Inertia::render('News/Show', [
            'news' => [
                'id' => $newsAnnouncement->id,
                'title' => $newsAnnouncement->title,
                'description' => $newsAnnouncement->description,
                'image_url' => $newsAnnouncement->image_url,
                'category' => $newsAnnouncement->newsType?->name ?? 'General',
                'created_at' => $newsAnnouncement->created_at->format('Y-m-d H:i A'),
            ],
            'meta' => [
                'title' => $newsAnnouncement->title,
                'description' => \Illuminate\Support\Str::limit(strip_tags($newsAnnouncement->description), 160),
                'image' => $newsAnnouncement->image_url,
                'url' => route('news.show', $newsAnnouncement),
            ],
        ]);
    }
}
