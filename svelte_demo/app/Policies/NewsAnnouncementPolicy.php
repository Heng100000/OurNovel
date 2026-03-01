<?php

declare(strict_types=1);

namespace App\Policies;

use App\Models\NewsAnnouncement;
use Illuminate\Auth\Access\HandlesAuthorization;
use Illuminate\Foundation\Auth\User as AuthUser;

class NewsAnnouncementPolicy
{
    use HandlesAuthorization;

    public function viewAny(AuthUser $authUser): bool
    {
        return $authUser->can('ViewAny:NewsAnnouncement');
    }

    public function view(AuthUser $authUser, NewsAnnouncement $newsAnnouncement): bool
    {
        return $authUser->can('View:NewsAnnouncement');
    }

    public function create(AuthUser $authUser): bool
    {
        return $authUser->can('Create:NewsAnnouncement');
    }

    public function update(AuthUser $authUser, NewsAnnouncement $newsAnnouncement): bool
    {
        return $authUser->can('Update:NewsAnnouncement');
    }

    public function delete(AuthUser $authUser, NewsAnnouncement $newsAnnouncement): bool
    {
        return $authUser->can('Delete:NewsAnnouncement');
    }

    public function restore(AuthUser $authUser, NewsAnnouncement $newsAnnouncement): bool
    {
        return $authUser->can('Restore:NewsAnnouncement');
    }

    public function forceDelete(AuthUser $authUser, NewsAnnouncement $newsAnnouncement): bool
    {
        return $authUser->can('ForceDelete:NewsAnnouncement');
    }

    public function forceDeleteAny(AuthUser $authUser): bool
    {
        return $authUser->can('ForceDeleteAny:NewsAnnouncement');
    }

    public function restoreAny(AuthUser $authUser): bool
    {
        return $authUser->can('RestoreAny:NewsAnnouncement');
    }

    public function replicate(AuthUser $authUser, NewsAnnouncement $newsAnnouncement): bool
    {
        return $authUser->can('Replicate:NewsAnnouncement');
    }

    public function reorder(AuthUser $authUser): bool
    {
        return $authUser->can('Reorder:NewsAnnouncement');
    }
}
