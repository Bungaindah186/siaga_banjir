<?php

namespace App\Http\Controllers;

use App\Models\FloodAlert;
use Illuminate\Http\JsonResponse;

class FloodAlertController extends Controller
{
    public function index(): JsonResponse
    {
        $alerts = FloodAlert::query()
            ->where('is_active', true)
            ->latest()
            ->limit(10)
            ->get([
                'id',
                'region_name',
                'status',
                'title',
                'description',
                'water_level_cm',
                'rise_rate_cm_per_hour',
                'latitude',
                'longitude',
                'created_at',
                'updated_at',
            ]);

        return response()->json([
            'data' => $alerts,
        ]);
    }
}