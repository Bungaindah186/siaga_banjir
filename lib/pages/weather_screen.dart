import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../services/padang_region_service.dart';

import '../navigation/app_routes.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../widgets/feature_page_shell.dart';
import '../widgets/reference_components.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({
    super.key,
    required this.account,
    required this.locationService,
  });

  final AuthenticatedUser account;
  final LocationService locationService;

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late final ApiClient _apiClient;

  final PadangRegionService _regionService = PadangRegionService();

  Map<String, dynamic>? _weather;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _apiClient = ApiClient();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Ambil posisi GPS pengguna.
      final position = await widget.locationService
          .checkAndGetCurrentPosition();

      if (!mounted) return;

      // 2. Periksa apakah lokasi berhasil didapatkan.
      if (position.status != LocationStatus.available ||
          position.position == null) {
        String message;
        switch (position.status) {
          case LocationStatus.permissionDenied:
            message =
                'Izin lokasi belum diberikan. Aktifkan izin lokasi '
                'di browser, lalu coba lagi.';
            break;

          case LocationStatus.permissionDeniedForever:
            message =
                'Izin lokasi diblokir. Buka pengaturan izin lokasi '
                'browser, izinkan akses lokasi, lalu coba lagi.';
            break;

          case LocationStatus.serviceDisabled:
            message =
                'Layanan lokasi tidak aktif. Aktifkan lokasi pada '
                'perangkat, lalu coba lagi.';
            break;

          default:
            message =
                'Lokasi GPS belum berhasil didapatkan. '
                'Periksa izin lokasi dan coba lagi.';
        }
        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });

        return;
      }

      // 3. Ubah koordinat GPS menjadi titik peta.
      final gpsPosition = position.position!;
      final point = LatLng(gpsPosition.latitude, gpsPosition.longitude);

      // 4. Cari kelurahan tempat pengguna berada.
      final region = await _regionService.findRegion(point);

      if (!mounted) return;

      if (region == null) {
        setState(() {
          _errorMessage =
              'Lokasi kamu tidak ditemukan dalam wilayah Kota Padang. '
              'Data cuaca hanya tersedia untuk wilayah Kota Padang.';
          _isLoading = false;
        });

        return;
      }

      // 5. Ambil data cuaca BMKG berdasarkan kode ADM4 kelurahan.
      final result = await _apiClient.fetchWeather(adm4: region.adm4);

      if (!mounted) return;

      // 6. Tampilkan nama kelurahan hasil pencarian GPS.
      final weather = Map<String, dynamic>.from(result);
      weather['location'] = region.name;

      setState(() {
        _weather = weather;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Terjadi kesalahan saat menentukan lokasi atau mengambil '
            'data cuaca. Periksa koneksi dan izin lokasi, lalu coba lagi.';
        _isLoading = false;
      });
    }
  }

  void _openRiver() {
    Navigator.of(context).pushNamed(
      AppRoutes.riverHeight,
      arguments: AppRouteArguments(
        account: widget.account,
        locationService: widget.locationService,
      ),
    );
  }

  String _formatValue(dynamic value, {String suffix = ''}) {
    if (value == null || value.toString().isEmpty) {
      return '--';
    }

    return '$value$suffix';
  }

  IconData _weatherIcon(String description) {
    final text = description.toLowerCase();

    if (text.contains('petir') || text.contains('guntur')) {
      return Icons.thunderstorm_rounded;
    }

    if (text.contains('hujan')) {
      return Icons.water_drop_rounded;
    }

    if (text.contains('kabut') || text.contains('kabur')) {
      return Icons.foggy;
    }

    if (text.contains('cerah')) {
      return Icons.wb_sunny_rounded;
    }

    return Icons.cloud_queue_rounded;
  }

  List<Map<String, dynamic>> get _forecasts {
    final data = _weather?['forecasts'];

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _formatForecastTime(dynamic value) {
    if (value == null) {
      return 'Waktu tidak tersedia';
    }

    final dateTime = DateTime.tryParse(value.toString());

    if (dateTime == null) {
      return value.toString();
    }

    final localTime = dateTime.toLocal();

    final day = localTime.day.toString().padLeft(2, '0');
    final month = localTime.month.toString().padLeft(2, '0');
    final hour = localTime.hour.toString().padLeft(2, '0');
    final minute = localTime.minute.toString().padLeft(2, '0');

    return '$day/$month • $hour:$minute';
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final description =
        _weather?['description']?.toString() ?? 'Tidak tersedia';

    final location = _weather?['location']?.toString() ?? 'Padang';

    final temperature = _weather?['temperature_c'];
    final humidity = _weather?['humidity_percent'];
    final wind = _weather?['wind_kmh'];
    final forecastTime = _weather?['forecast_time'];
    final source = _weather?['source']?.toString() ?? 'BMKG';

    return FeaturePageShell(
      title: 'Cuaca',
      account: widget.account,
      locationService: widget.locationService,
      activeTab: 'Cuaca',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(27, 22, 27, 100),
        children: [
          Row(
            children: [
              const Expanded(
                child: ReferenceTab(
                  label: 'Cuaca saat ini',
                  selected: true,
                  onTap: _noAction,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ReferenceTab(
                  label: 'Ketinggian Sungai',
                  selected: false,
                  onTap: _openRiver,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Kartu utama cuaca
          ReferenceCard(
            padding: const EdgeInsets.all(19),
            child: _isLoading
                ? const SizedBox(
                    height: 115,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _errorMessage != null
                ? Column(
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 55,
                        color: Color(0xFF71808D),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Data cuaca belum tersedia',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF0B2E3B),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF71808D),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _loadWeather,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba lagi'),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Icon(
                        _weatherIcon(description),
                        size: 62,
                        color: const Color(0xFF0B2E3B),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatValue(temperature, suffix: '°C'),
                              style: const TextStyle(
                                color: Color(0xFF0B2E3B),
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              description,
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              location,
                              style: const TextStyle(
                                color: Color(0xFF71808D),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 15),

          // Informasi cuaca dari API
          if (!_isLoading && _errorMessage == null)
            ReferenceCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _WeatherMetric(
                    label: 'Lembap',
                    value: _formatValue(humidity, suffix: '%'),
                  ),
                  _WeatherMetric(
                    label: 'Angin',
                    value: _formatValue(wind, suffix: ' km/j'),
                  ),
                  const _WeatherMetric(label: 'Curah hujan', value: '--'),
                ],
              ),
            ),

          if (!_isLoading && _errorMessage == null) ...[
            const SizedBox(height: 8),

            Text(
              'Sumber data: $source',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF71808D), fontSize: 11),
            ),

            if (forecastTime != null) ...[
              const SizedBox(height: 4),
              Text(
                'Waktu prakiraan: $forecastTime',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF71808D), fontSize: 11),
              ),
            ],

            const SizedBox(height: 8),

            Center(
              child: TextButton.icon(
                onPressed: _loadWeather,
                icon: const Icon(Icons.refresh),
                label: const Text('Perbarui data cuaca'),
              ),
            ),
          ],

          const SizedBox(height: 20),
          const ReferenceSectionHeading('Prakiraan Cuaca'),

          const SizedBox(height: 8),

          if (_isLoading)
            const ReferenceCard(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            ReferenceCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Prakiraan cuaca belum dapat dimuat.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _loadWeather,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba lagi'),
                  ),
                ],
              ),
            )
          else if (_forecasts.isEmpty)
            const ReferenceCard(
              padding: EdgeInsets.all(16),
              child: Text(
                'Data prakiraan cuaca belum tersedia.',
                textAlign: TextAlign.center,
              ),
            )
          else
            SizedBox(
              height: 172,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _forecasts.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final forecast = _forecasts[index];

                  final description =
                      forecast['description']?.toString() ?? 'Tidak tersedia';

                  final temperature = forecast['temperature_c'];

                  return SizedBox(
                    width: 125,
                    child: ReferenceCard(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatForecastTime(forecast['forecast_time']),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF0B2E3B),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Icon(
                            _weatherIcon(description),
                            size: 34,
                            color: const Color(0xFF0B2E3B),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            temperature == null ? '--°C' : '$temperature°C',
                            style: const TextStyle(
                              color: Color(0xFF0B2E3B),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

void _noAction() {}

class _WeatherMetric extends StatelessWidget {
  const _WeatherMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF0B2E3B), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF0B2E3B),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
