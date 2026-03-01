<?php

declare(strict_types=1);

namespace App\Policies;

use App\Models\UserAddress;
use Illuminate\Auth\Access\HandlesAuthorization;
use Illuminate\Foundation\Auth\User as AuthUser;

class UserAddressPolicy
{
    use HandlesAuthorization;

    public function viewAny(AuthUser $authUser): bool
    {
        return true;
    }

    public function view(AuthUser $authUser, UserAddress $userAddress): bool
    {
        return $authUser->id === $userAddress->user_id || $authUser->can('View:UserAddress');
    }

    public function create(AuthUser $authUser): bool
    {
        return true;
    }

    public function update(AuthUser $authUser, UserAddress $userAddress): bool
    {
        return $authUser->id === $userAddress->user_id || $authUser->can('Update:UserAddress');
    }

    public function delete(AuthUser $authUser, UserAddress $userAddress): bool
    {
        return $authUser->id === $userAddress->user_id || $authUser->can('Delete:UserAddress');
    }

    public function restore(AuthUser $authUser, UserAddress $userAddress): bool
    {
        return $authUser->can('Restore:UserAddress');
    }

    public function forceDelete(AuthUser $authUser, UserAddress $userAddress): bool
    {
        return $authUser->can('ForceDelete:UserAddress');
    }

    public function forceDeleteAny(AuthUser $authUser): bool
    {
        return $authUser->can('ForceDeleteAny:UserAddress');
    }

    public function restoreAny(AuthUser $authUser): bool
    {
        return $authUser->can('RestoreAny:UserAddress');
    }

    public function replicate(AuthUser $authUser, UserAddress $userAddress): bool
    {
        return $authUser->can('Replicate:UserAddress');
    }

    public function reorder(AuthUser $authUser): bool
    {
        return $authUser->can('Reorder:UserAddress');
    }
}
