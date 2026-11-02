<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CitizenReport;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class CitizenReportController extends Controller
{
    /**
     * Mengirim laporan warga.
     */
    
public function store(Request $request): JsonResponse
{
    $validated = $request->validate([
        'event_type' => 'required|string|max:255',
        'location_name' => 'required|string|max:255',
        'latitude' => 'nullable|numeric|between:-90,90',
        'longitude' => 'nullable|numeric|between:-180,180',
        'description' => 'required|string',
        'event_time' => 'nullable|string|max:255',
        'water_level_cm' => 'nullable|numeric|min:0',
        'photo' => 'nullable|image|mimes:jpg,jpeg,png,webp|max:5120',
    ]);

    if ($request->hasFile('photo')) {
        $validated['photo_path'] = $request->file('photo')
            ->store('citizen-reports', 'public');
    }

    unset($validated['photo']);

    $report = CitizenReport::create([
        ...$validated,
        'user_id' => $request->user()->id,
        'status' => 'Menunggu Verifikasi',
    ]);

    return response()->json([
        'message' => 'Laporan berhasil dikirim.',
        'data' => $report,
    ], 201);
}


    /**
     * Mengambil riwayat laporan milik warga yang sedang login.
     */
    public function myReports(Request $request): JsonResponse
    {
        $reports = CitizenReport::where('user_id', $request->user()->id)
            ->latest()
            ->get();

        return response()->json([
            'message' => 'Riwayat laporan berhasil diambil.',
            'data' => $reports,
        ]);
    }
}