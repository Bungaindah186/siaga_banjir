<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class NotificationPreferenceController extends Controller
{
    /**
     * Mengambil preferensi notifikasi pengguna.
     */
    public function show(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'success' => true,
            'data' => [
                'notification_alert' => $user->notification_alert,
                'notification_river' => $user->notification_river,
                'notification_education' => $user->notification_education,
            ],
        ]);
    }

    /**
     * Memperbarui preferensi notifikasi pengguna.
     */
    public function update(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'notification_alert' => ['sometimes', 'required', 'boolean'],
            'notification_river' => ['sometimes', 'required', 'boolean'],
            'notification_education' => ['sometimes', 'required', 'boolean'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'message' => 'Pengaturan notifikasi tidak valid.',
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();

        $user->fill($validator->validated());
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Pengaturan notifikasi berhasil disimpan.',
            'data' => [
                'notification_alert' => $user->notification_alert,
                'notification_river' => $user->notification_river,
                'notification_education' => $user->notification_education,
            ],
        ]);
    }
}