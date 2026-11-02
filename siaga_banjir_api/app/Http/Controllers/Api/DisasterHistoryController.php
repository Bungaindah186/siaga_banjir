<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\DisasterHistory;

class DisasterHistoryController extends Controller
{
    public function index()
    {
        $histories = DisasterHistory::orderBy('event_time', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'message' => 'Riwayat bencana berhasil diambil.',
            'data' => $histories,
        ]);
    }

    public function show($id)
    {
        $history = DisasterHistory::find($id);

        if (!$history) {
            return response()->json([
                'success' => false,
                'message' => 'Data riwayat bencana tidak ditemukan.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $history,
        ]);
    }
}