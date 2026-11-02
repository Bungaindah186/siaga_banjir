<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FloodAlert;
use App\Models\RiverReading;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class RiverReadingController extends Controller
{
    /**
     * Mengambil riwayat pengukuran berdasarkan titik pemantauan.
     */
    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'flood_alert_id' => [
                'required',
                'integer',
                'exists:flood_alerts,id',
            ],
            'hours' => ['nullable', 'integer', 'min:1', 'max:168'],
        ]);

        $hours = $validated['hours'] ?? 6;

        $readings = RiverReading::query()
            ->where('flood_alert_id', $validated['flood_alert_id'])
            ->where('measured_at', '>=', now()->subHours($hours))
            ->orderBy('measured_at')
            ->get([
                'id',
                'flood_alert_id',
                'water_level_cm',
                'rise_rate_cm_per_hour',
                'measured_at',
            ]);

        return response()->json([
            'data' => $readings,
        ]);
    }

    /**
     * Menyimpan pengukuran baru oleh petugas.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'flood_alert_id' => [
                'required',
                'integer',
                'exists:flood_alerts,id',
            ],
            'water_level_cm' => [
                'required',
                'numeric',
                'min:0',
                'max:999999.99',
            ],
            'rise_rate_cm_per_hour' => [
                'nullable',
                'numeric',
                'min:-999999.99',
                'max:999999.99',
            ],
            'measured_at' => ['nullable', 'date'],
        ]);

        $alert = FloodAlert::findOrFail(
            $validated['flood_alert_id']
        );

        $reading = RiverReading::create([
            'flood_alert_id' => $alert->id,
            'water_level_cm' => $validated['water_level_cm'],
            'rise_rate_cm_per_hour' =>
                $validated['rise_rate_cm_per_hour'] ?? null,
            'recorded_by' => $request->user()->id,
            'measured_at' => $validated['measured_at'] ?? now(),
        ]);

        // Perbarui data terkini yang digunakan Home dan Status Siaga.
        $alert->update([
            'water_level_cm' => $reading->water_level_cm,
            'rise_rate_cm_per_hour' =>
                $reading->rise_rate_cm_per_hour,
        ]);

        return response()->json([
            'message' => 'Pengukuran ketinggian air berhasil disimpan.',
            'data' => $reading,
        ], 201);
    }
}