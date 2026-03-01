<?php

namespace App\Observers;

use App\Models\Book;

class BookObserver
{
    public bool $afterCommit = true;

    public function __construct(protected \App\Services\FcmService $fcmService) {}

    protected function notifyClients(string $action = 'updated'): void
    {
        $this->fcmService->sendToTopic('books_update', [
            'type' => 'book_updated',
            'timestamp' => (string) now()->timestamp,
        ]);
        event(new \App\Events\RealTimeUpdate('Book', $action));
    }

    /**
     * Handle the Book "created" event.
     */
    public function created(Book $book): void
    {
        $this->notifyClients('created');
    }

    /**
     * Handle the Book "updated" event.
     */
    public function updated(Book $book): void
    {
        $this->notifyClients('updated');
    }

    /**
     * Handle the Book "deleted" event.
     */
    public function deleted(Book $book): void
    {
        $this->notifyClients('deleted');
    }

    /**
     * Handle the Book "restored" event.
     */
    public function restored(Book $book): void
    {
        $this->notifyClients('restored');
    }

    /**
     * Handle the Book "force deleted" event.
     */
    public function forceDeleted(Book $book): void
    {
        $this->notifyClients('forceDeleted');
    }
}
