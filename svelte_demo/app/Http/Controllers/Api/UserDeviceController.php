<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class UserDeviceController extends Controller
{
    /**
     * Register or update a user's device FCM token.
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'fcm_token' => 'required|string',
            'device_type' => 'nullable|string|max:20',
        ]);

        $device = $request->user()->devices()->updateOrCreate(
            ['fcm_token' => $request->fcm_token],
            ['device_type' => $request->device_type]
        );

        return response()->json([
            'message' => 'Device registered successfully',
            'device' => $device
        ]);
    }

    /**
     * Remove a registered device (e.g., on logout).
     */
    public function destroy(Request $request): JsonResponse
    {
        $request->validate([
            'fcm_token' => 'required|string',
        ]);

        $request->user()->devices()
            ->where('fcm_token', $request->fcm_token)
            ->delete();

        return response()->json([
            'message' => 'Device removed successfully'
        ]);
    }
}
