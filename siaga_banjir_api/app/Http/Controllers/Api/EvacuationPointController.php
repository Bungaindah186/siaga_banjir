<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\EvacuationPoint;
use Illuminate\Http\JsonResponse;

class EvacuationPointController extends Controller
{
    public function index(): JsonResponse
    {
        $points = EvacuationPoint::query()
            ->whereIn('status', ['active', 'full'])
            ->orderBy('name')
            ->get([
                'id',
                'name',
                'address',
                'latitude',
                'longitude',
                'capacity',
                'current_occupancy',
                'status',
                'description',
            ]);

        return response()->json([
            'success' => true,
            'message' => 'Data titik pengungsian berhasil diambil.',
            'data' => $points,
        ]);
    }
}