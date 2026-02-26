<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class NotificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $notifications = $request->user()->appNotifications()->latest()->get();
        return response()->json([
            'success' => true,
            'data' => $notifications,
        ]);
    }

    public function show(Notification $notification): JsonResponse
    {
        $this->authorize('view', $notification);
        return response()->json([
            'success' => true,
            'data' => $notification,
        ]);
    }

    public function markAsRead(Notification $notification): JsonResponse
    {
        $this->authorize('update', $notification);
        $notification->update(['is_read' => true]);
        return response()->json([
            'success' => true,
            'data' => $notification,
        ]);
    }

    public function markAllAsRead(Request $request): JsonResponse
    {
        $request->user()->appNotifications()->update(['is_read' => true]);
        return response()->json([
            'success' => true,
            'message' => 'All notifications marked as read',
        ]);
    }

    public function destroy(Notification $notification): JsonResponse
    {
        $this->authorize('delete', $notification);
        $notification->delete();
        return response()->json([
            'success' => true,
            'message' => 'Notification deleted',
        ]);
    }

    public function destroyAll(Request $request): JsonResponse
    {
        $request->user()->appNotifications()->delete();
        return response()->json([
            'success' => true,
            'message' => 'All notifications deleted',
        ]);
    }
}
