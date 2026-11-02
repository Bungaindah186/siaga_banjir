<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UserDeviceController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'firebase_installation_id' => [
                'required',
                'string',
                'max:512',
            ],
            'platform' => ['required', 'string', 'in:android,ios'],
        ]);

        $device = $request->user()
            ->devices()
            ->updateOrCreate(
                [
                    'firebase_installation_id' =>
                        $validated['firebase_installation_id'],
                ],
                [
                    'platform' => $validated['platform'],
                ],
            );

        return response()->json([
            'success' => true,
            'message' => 'Perangkat berhasil didaftarkan.',
            'data' => [
                'id' => $device->id,
                'platform' => $device->platform,
            ],
        ]);
    }

    public function destroy(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'firebase_installation_id' => [
                'required',
                'string',
                'max:512',
            ],
        ]);

        $request->user()
            ->devices()
            ->where(
                'firebase_installation_id',
                $validated['firebase_installation_id']
            )
            ->delete();

        return response()->json([
            'success' => true,
            'message' => 'Perangkat berhasil dihapus.',
        ]);
    }
}