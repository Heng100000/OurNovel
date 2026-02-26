<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

use App\Http\Requests\StoreUserAddressRequest;
use App\Http\Resources\Api\UserAddressResource;
use App\Models\UserAddress;
use Illuminate\Http\JsonResponse;

class UserAddressController extends Controller
{
    public function index(Request $request)
    {
        $addresses = $request->user()->addresses()->orderByDesc('is_default')->latest()->get();
        return UserAddressResource::collection($addresses);
    }

    public function store(StoreUserAddressRequest $request): JsonResource
    {
        $user = $request->user();
        $data = $request->validated();

        if ($data['is_default'] ?? false) {
            $user->addresses()->update(['is_default' => false]);
        }

        // If it's their first address, make it default automatically
        if ($user->addresses()->count() === 0) {
            $data['is_default'] = true;
        }

        $address = $user->addresses()->create($data);

        return new UserAddressResource($address);
    }

    public function update(StoreUserAddressRequest $request, UserAddress $address): JsonResource|JsonResponse
    {
        if ($address->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $data = $request->validated();

        if ($data['is_default'] ?? false) {
            $request->user()->addresses()->update(['is_default' => false]);
        }

        $address->update($data);

        return new UserAddressResource($address);
    }

    public function destroy(Request $request, UserAddress $address): JsonResponse
    {
        if ($address->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $address->delete();

        // If they deleted the default, set another one to default if exists
        if ($address->is_default) {
            $nextAddress = $request->user()->addresses()->latest()->first();
            if ($nextAddress) {
                $nextAddress->update(['is_default' => true]);
            }
        }

        return response()->json(null, 204);
    }

    public function setDefault(Request $request, UserAddress $address): JsonResource|JsonResponse
    {
        if ($address->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $request->user()->addresses()->update(['is_default' => false]);
        $address->update(['is_default' => true]);

        return new UserAddressResource($address);
    }
}
