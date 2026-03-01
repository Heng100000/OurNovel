<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\Api\NewsAnnouncementResource;
use App\Models\NewsAnnouncement;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class NewsAnnouncementController extends Controller
{
    /**
     * Display a listing of the news announcements.
     */
    public function index(): AnonymousResourceCollection
    {
        $news = NewsAnnouncement::with('newsType')->latest()->get();

        return NewsAnnouncementResource::collection($news);
    }

    /**
     * Display the specified news announcement.
     */
    public function show(NewsAnnouncement $newsAnnouncement): NewsAnnouncementResource
    {
        return new NewsAnnouncementResource($newsAnnouncement);
    }
}
