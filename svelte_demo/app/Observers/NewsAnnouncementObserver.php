<?php

namespace App\Observers;

use App\Models\NewsAnnouncement;
use App\Events\RealTimeUpdate;

class NewsAnnouncementObserver
{
    /**
     * Handle the NewsAnnouncement "created" event.
     */
    public function created(NewsAnnouncement $newsAnnouncement): void
    {
        event(new RealTimeUpdate('NewsAnnouncement', 'created'));
    }

    /**
     * Handle the NewsAnnouncement "updated" event.
     */
    public function updated(NewsAnnouncement $newsAnnouncement): void
    {
        event(new RealTimeUpdate('NewsAnnouncement', 'updated'));
    }

    /**
     * Handle the NewsAnnouncement "deleted" event.
     */
    public function deleted(NewsAnnouncement $newsAnnouncement): void
    {
        event(new RealTimeUpdate('NewsAnnouncement', 'deleted'));
    }
}
