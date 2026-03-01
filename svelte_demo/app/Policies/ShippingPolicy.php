<?php

declare(strict_types=1);

namespace App\Policies;

use App\Models\Shipping;
use Illuminate\Auth\Access\HandlesAuthorization;
use Illuminate\Foundation\Auth\User as AuthUser;

class ShippingPolicy
{
    use HandlesAuthorization;

    public function viewAny(AuthUser $authUser): bool
    {
        return $authUser->can('ViewAny:Shipping');
    }

    public function view(AuthUser $authUser, Shipping $shipping): bool
    {
        return $authUser->can('View:Shipping');
    }

    public function create(AuthUser $authUser): bool
    {
        return $authUser->can('Create:Shipping');
    }

    public function update(AuthUser $authUser, Shipping $shipping): bool
    {
        return $authUser->can('Update:Shipping');
    }

    public function delete(AuthUser $authUser, Shipping $shipping): bool
    {
        return $authUser->can('Delete:Shipping');
    }

    public function restore(AuthUser $authUser, Shipping $shipping): bool
    {
        return $authUser->can('Restore:Shipping');
    }

    public function forceDelete(AuthUser $authUser, Shipping $shipping): bool
    {
        return $authUser->can('ForceDelete:Shipping');
    }

    public function forceDeleteAny(AuthUser $authUser): bool
    {
        return $authUser->can('ForceDeleteAny:Shipping');
    }

    public function restoreAny(AuthUser $authUser): bool
    {
        return $authUser->can('RestoreAny:Shipping');
    }

    public function replicate(AuthUser $authUser, Shipping $shipping): bool
    {
        return $authUser->can('Replicate:Shipping');
    }

    public function reorder(AuthUser $authUser): bool
    {
        return $authUser->can('Reorder:Shipping');
    }
}
