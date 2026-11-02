<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class BmkgWeatherController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        // Wilayah default untuk menjaga kompatibilitas
        // dengan halaman Home yang sudah ada.
        $defaultAdm4 = '13.71.11.1004';

        // Ambil kode wilayah dari parameter URL jika tersedia.
        $adm4 = $request->query('adm4', $defaultAdm4);

        // Pastikan format kode wilayah sesuai format adm4 BMKG.
        if (
            ! is_string($adm4) ||
            ! preg_match('/^\d{2}\.\d{2}\.\d{2}\.\d{4}$/', $adm4)
        ) {
            return response()->json([
                'message' => 'Kode wilayah tidak valid.',
            ], 422);
        }

        try {
            $response = Http::acceptJson()
                ->timeout(12)
                ->get(
                    'https://api.bmkg.go.id/publik/prakiraan-cuaca',
                    [
                        'adm4' => $adm4,
                    ]
                );

            if (! $response->successful()) {
                return response()->json([
                    'message' => 'Data BMKG belum dapat diambil.',
                ], 502);
            }

            $payload = $response->json();

            $dailyForecasts =
                $payload['data'][0]['cuaca'] ?? [];

            $forecasts = [];

            foreach ($dailyForecasts as $daily) {
                foreach ($daily as $item) {
                    $forecasts[] = $item;
                }
            }

            if (empty($forecasts)) {
                return response()->json([
                    'message' => 'Prakiraan cuaca belum tersedia.',
                ], 502);
            }

            $now = now('Asia/Jakarta')
                ->format('Y-m-d H:i:s');

            $current = null;
            $currentIndex = 0;

            foreach ($forecasts as $index => $item) {
                if (
                    isset($item['local_datetime']) &&
                    $item['local_datetime'] >= $now
                ) {
                    $current = $item;
                    $currentIndex = $index;
                    break;
                }
            }

            if ($current === null) {
                $current = $forecasts[0];
                $currentIndex = 0;
            }

            // Ambil hingga 8 prakiraan mulai dari waktu terdekat.
            $upcomingForecasts = array_slice(
                $forecasts,
                $currentIndex,
                8
            );

            $formattedForecasts = array_map(
                function ($item) {
                    return [
                        'forecast_time' =>
                            $item['local_datetime'] ?? null,

                        'description' =>
                            $item['weather_desc']
                            ?? 'Tidak tersedia',

                        'temperature_c' =>
                            $item['t'] ?? null,

                        'humidity_percent' =>
                            $item['hu'] ?? null,

                        'wind_kmh' =>
                            $item['ws'] ?? null,
                    ];
                },
                $upcomingForecasts
            );

            return response()->json([
                'location' =>
                    $payload['lokasi']['desa']
                    ?? 'Tidak diketahui',

                'forecast_time' =>
                    $current['local_datetime'] ?? null,

                'description' =>
                    $current['weather_desc']
                    ?? 'Tidak tersedia',

                'temperature_c' =>
                    $current['t'] ?? null,

                'humidity_percent' =>
                    $current['hu'] ?? null,

                'wind_kmh' =>
                    $current['ws'] ?? null,

                'source' => 'BMKG',

                'forecasts' => $formattedForecasts,
            ]);
        } catch (\Throwable $e) {
            report($e);

            return response()->json([
                'message' =>
                    'Gagal menghubungi layanan BMKG.',
            ], 502);
        }
    }
}