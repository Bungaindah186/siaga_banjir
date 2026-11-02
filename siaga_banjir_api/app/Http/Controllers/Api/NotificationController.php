<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * Menampilkan notifikasi dan jumlah yang belum dibaca.
     */
    public function index(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        $notifications = Notification::query()
            ->where('user_id', $userId)
            ->latest()
            ->get();

        $unreadCount = Notification::query()
            ->where('user_id', $userId)
            ->whereNull('read_at')
            ->count();

        return response()->json([
            'data' => $notifications,
            'unread_count' => $unreadCount,
        ]);
    }

    /**
     * Menandai satu notifikasi sebagai sudah dibaca.
     */
    public function markAsRead(
        Request $request,
        int $id
    ): JsonResponse {
        $notification = Notification::query()
            ->where('user_id', $request->user()->id)
            ->findOrFail($id);

        if ($notification->read_at === null) {
            $notification->read_at = now();
            $notification->save();
        }

        return response()->json([
            'message' => 'Notifikasi berhasil ditandai sudah dibaca.',
            'data' => $notification,
        ]);
    }

    /**
     * Menghapus satu notifikasi milik pengguna.
     */
    public function destroy(
        Request $request,
        int $id
    ): JsonResponse {
        $notification = Notification::query()
            ->where('user_id', $request->user()->id)
            ->findOrFail($id);

        $notification->delete();

        return response()->json([
            'message' => 'Notifikasi berhasil dihapus.',
        ]);
    }

    /**
     * Menghapus semua notifikasi milik pengguna.
     */
    public function destroyAll(Request $request): JsonResponse
    {
        Notification::query()
            ->where('user_id', $request->user()->id)
            ->delete();

        return response()->json([
            'message' => 'Semua notifikasi berhasil dihapus.',
        ]);
    }
}