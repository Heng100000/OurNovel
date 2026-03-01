<?php

declare(strict_types=1);

namespace App\Policies;

use App\Models\CartItem;
use Illuminate\Auth\Access\HandlesAuthorization;
use Illuminate\Foundation\Auth\User as AuthUser;

class CartItemPolicy
{
    use HandlesAuthorization;

    public function viewAny(AuthUser $authUser): bool
    {
        return true; // Any authenticated user can view their own collection
    }

    public function view(AuthUser $authUser, CartItem $cartItem): bool
    {
        return $authUser->id === $cartItem->user_id || $authUser->can('View:CartItem');
    }

    public function create(AuthUser $authUser): bool
    {
        return true; // Any authenticated user can create a cart item
    }

    public function update(AuthUser $authUser, CartItem $cartItem): bool
    {
        return $authUser->id === $cartItem->user_id || $authUser->can('Update:CartItem');
    }

    public function delete(AuthUser $authUser, CartItem $cartItem): bool
    {
        return $authUser->id === $cartItem->user_id || $authUser->can('Delete:CartItem');
    }

    public function restore(AuthUser $authUser, CartItem $cartItem): bool
    {
        return $authUser->can('Restore:CartItem');
    }

    public function forceDelete(AuthUser $authUser, CartItem $cartItem): bool
    {
        return $authUser->can('ForceDelete:CartItem');
    }

    public function forceDeleteAny(AuthUser $authUser): bool
    {
        return $authUser->can('ForceDeleteAny:CartItem');
    }

    public function restoreAny(AuthUser $authUser): bool
    {
        return $authUser->can('RestoreAny:CartItem');
    }

    public function replicate(AuthUser $authUser, CartItem $cartItem): bool
    {
        return $authUser->can('Replicate:CartItem');
    }

    public function reorder(AuthUser $authUser): bool
    {
        return $authUser->can('Reorder:CartItem');
    }
}
