<?php

namespace App\Observers;

use App\Models\Notification;
use App\Services\FcmService;

class NotificationObserver
{
    public bool $afterCommit = true;

    public function __construct(protected FcmService $fcmService)
    {
    }

    /**
     * Handle the Notification "created" event.
     */
    public function created(Notification $notification): void
    {
        if ($notification->user) {
            $this->fcmService->sendToUser(
                $notification->user,
                $notification->title,
                $notification->message
            );
        }
    }
}
