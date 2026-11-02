import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../navigation/app_routes.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../services/flood_alert_service.dart';
import '../widgets/feature_page_shell.dart';
import '../widgets/reference_components.dart';

import 'dart:ui' as ui;

class RiverHeightScreen extends StatefulWidget {
  const RiverHeightScreen({
    super.key,
    required this.account,
    required this.locationService,
  });

  final AuthenticatedUser account;
  final LocationService locationService;

  @override
  State<RiverHeightScreen> createState() => _RiverHeightScreenState();
}

class _RiverHeightScreenState extends State<RiverHeightScreen> {
  final FloodAlertService _floodAlertService = FloodAlertService();

  List<FloodAlert> _alerts = [];
  FloodAlert? _selectedAlert;
  List<RiverReading> _readings = [];

  bool _readingsLoading = false;
  bool _readingsFailed = false;

  bool _loading = true;
  bool _failed = false;

  static const double _searchRadiusKm = 3.0;

  @override
  void initState() {
    super.initState();
    _loadRiverData();
  }

  Future<void> _loadRiverData() async {
    setState(() {
      _loading = true;
      _failed = false;
      _readings = [];
      _readingsFailed = false;
    });

    try {
      // Ambil seluruh titik pantau aktif dari Laravel
      final allAlerts = await _floodAlertService.fetchAlerts();

      if (!mounted) return;

      // Periksa lokasi GPS pengguna
      final locationResult = await widget.locationService
          .checkAndGetCurrentPosition();

      if (!mounted) return;

      // Jika GPS tidak tersedia, tetap tampilkan semua titik pantau
      if (locationResult.status != LocationStatus.available ||
          locationResult.position == null) {
        setState(() {
          _alerts = allAlerts;
          _selectedAlert = null;
          _loading = false;
        });
        return;
      }

      final userPosition = LatLng(
        locationResult.position!.latitude,
        locationResult.position!.longitude,
      );

      final distance = Distance();

      // Cari titik pantau dalam radius 3 km
      final nearbyAlerts = allAlerts.where((alert) {
        final position = alert.position;
        if (position == null) return false;

        final distanceMeters = distance.as(
          LengthUnit.Meter,
          userPosition,
          position,
        );

        return distanceMeters <= _searchRadiusKm * 1000;
      }).toList();

      // Urutkan berdasarkan jarak terdekat
      nearbyAlerts.sort((a, b) {
        final distanceA = distance.as(
          LengthUnit.Meter,
          userPosition,
          a.position!,
        );

        final distanceB = distance.as(
          LengthUnit.Meter,
          userPosition,
          b.position!,
        );

        return distanceA.compareTo(distanceB);
      });

      final selectedAlert = nearbyAlerts.isNotEmpty ? nearbyAlerts.first : null;

      setState(() {
        // Simpan SEMUA titik pantau, bukan hanya radius 3 km
        _alerts = allAlerts;
        _selectedAlert = selectedAlert;
        _loading = false;
      });

      // Ambil riwayat lokasi terdekat
      if (selectedAlert != null) {
        await _loadReadingsForAlert(selectedAlert);
      }
    } catch (error) {
      debugPrint('Gagal memuat data ketinggian sungai: $error');

      if (!mounted) return;

      setState(() {
        _alerts = [];
        _selectedAlert = null;
        _readings = [];
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _loadReadingsForAlert(FloodAlert alert) async {
    if (!mounted) return;

    setState(() {
      _readingsLoading = true;
      _readingsFailed = false;
      _readings = [];
    });

    try {
      final readings = await _floodAlertService.fetchReadings(
        token: widget.account.token,
        floodAlertId: alert.id,
        hours: 6,
      );

      if (!mounted) return;

      setState(() {
        _readings = readings;
        _readingsLoading = false;
      });
    } catch (error) {
      debugPrint('Gagal mengambil riwayat sungai: $error');

      if (!mounted) return;

      setState(() {
        _readings = [];
        _readingsLoading = false;
        _readingsFailed = true;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'awas':
        return const Color(0xFFC8282B);
      case 'waspada':
        return const Color(0xFF987300);
      case 'siaga':
        return const Color(0xFFBB6400);
      case 'aman':
        return const Color(0xFF2EA361);
      default:
        return Colors.blueGrey;
    }
  }

  void _openWeather(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.weather,
      arguments: AppRouteArguments(
        account: widget.account,
        locationService: widget.locationService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FeaturePageShell(
    title: 'Ketinggian Sungai',
    account: widget.account,
    locationService: widget.locationService,
    activeTab: 'Cuaca',
    child: ListView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 100),
      children: [
        Row(
          children: [
            Expanded(
              child: ReferenceTab(
                label: 'Cuaca saat ini',
                selected: false,
                onTap: () => _openWeather(context),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: ReferenceTab(
                label: 'Ketinggian Sungai',
                selected: true,
                onTap: _noop,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        const ReferenceSectionHeading('Lokasi pemantauan saat ini'),
        const SizedBox(height: 10),

        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_failed)
          _InfoMessage(
            message: 'Gagal mengambil data dari server.',
            onRetry: _loadRiverData,
          )
        else if (_selectedAlert == null)
          _InfoMessage(
            message: 'Belum ada titik pemantauan dengan data dalam radius 3 km dari lokasi pengguna.',
            onRetry: _loadRiverData,
          )
        else ...[
          _CurrentRiverCard(
            alert: _selectedAlert!,
            color: _statusColor(_selectedAlert!.status),
          ),
        ],

        const SizedBox(height: 22),

        const ReferenceSectionHeading('Tren ketinggian air'),
        const SizedBox(height: 8),

        Container(
          height: 230,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: _readingsLoading
              ? const Center(child: CircularProgressIndicator())
              : _readingsFailed
              ? Center(
                  child: TextButton(
                    onPressed: _selectedAlert == null
                        ? null
                        : () => _loadReadingsForAlert(_selectedAlert!),
                    child: const Text('Coba ambil riwayat lagi'),
                  ),
                )
              : _readings.isEmpty
              ? const Center(
                  child: Text(
                    'Riwayat pengukuran ketinggian air belum tersedia.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF71808D), fontSize: 12),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jumlah pengukuran: ${_readings.length}',
                      style: const TextStyle(
                        color: Color(0xFF71808D),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(child: _RiverTrendChart(readings: _readings)),
                    const SizedBox(height: 8),
                    Text(
                      'Pengukuran terakhir: ${_readings.last.waterLevelCm.toStringAsFixed(0)} cm',
                      style: const TextStyle(
                        color: Color(0xFF0B2E3B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),

        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 23),
          child: Text(
            'Grafik akan ditampilkan setelah tersedia data riwayat pengukuran.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF71808D), fontSize: 11),
          ),
        ),

        const ReferenceSectionHeading('Titik pantau lain'),
        const SizedBox(height: 10),

        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_alerts.length <= 1)
          const Text(
            'Belum ada titik pantau lain di sekitar lokasi pengguna.',
            style: TextStyle(color: Color(0xFF71808D)),
          )
        else
          ..._alerts
              .where((alert) => alert.id != _selectedAlert?.id)
              .map(
                (alert) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MonitorRow(
                    name: alert.regionName,
                    level: alert.waterLevelCm == null
                        ? 'Belum tersedia'
                        : '${alert.waterLevelCm!.toStringAsFixed(0)} cm',
                    status: alert.status,
                    color: _statusColor(alert.status),
                    onTap: () {
                      setState(() {
                        _selectedAlert = alert;
                      });

                      _loadReadingsForAlert(alert);
                    },
                  ),
                ),
              ),
      ],
    ),
  );
}

void _noop() {}

class _CurrentRiverCard extends StatelessWidget {
  const _CurrentRiverCard({required this.alert, required this.color});

  final FloodAlert alert;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final waterLevel = alert.waterLevelCm == null
        ? 'Belum tersedia'
        : '${alert.waterLevelCm!.toStringAsFixed(0)} cm';

    final riseRate = alert.riseRateCmPerHour == null
        ? 'Belum tersedia'
        : '${alert.riseRateCmPerHour!.toStringAsFixed(0)} cm/jam';

    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alert.regionName,
              style: const TextStyle(
                color: Color(0xFF0B2E3B),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Ketinggian air',
                    style: TextStyle(color: Color(0xFF666666)),
                  ),
                ),
                Text(
                  waterLevel,
                  style: const TextStyle(
                    color: Color(0xFF0B2E3B),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Perubahan air',
                    style: TextStyle(color: Color(0xFF666666)),
                  ),
                ),
                Text(
                  riseRate,
                  style: const TextStyle(
                    color: Color(0xFF0B2E3B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ReferenceStatusPill(label: alert.status, color: color),
            const SizedBox(height: 12),
            Text(
              alert.title,
              style: const TextStyle(color: Color(0xFF71808D), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoMessage extends StatelessWidget {
  const _InfoMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF71808D)),
        ),
        const SizedBox(height: 10),
        TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
      ],
    ),
  );
}

class _MonitorRow extends StatelessWidget {
  const _MonitorRow({
    required this.name,
    required this.level,
    required this.status,
    required this.color,
    required this.onTap,
  });

  final String name;
  final String level;
  final String status;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    elevation: 2,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Color(0xFF666666))),
                  const SizedBox(height: 4),
                  ReferenceStatusPill(label: status, color: color),
                ],
              ),
            ),
            Text(
              level,
              style: const TextStyle(
                color: Color(0xFF0B2E3B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RiverTrendChart extends StatelessWidget {
  const _RiverTrendChart({required this.readings});

  final List<RiverReading> readings;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RiverTrendPainter(readings),
      child: const SizedBox.expand(),
    );
  }
}

class _RiverTrendPainter extends CustomPainter {
  _RiverTrendPainter(this.readings);

  final List<RiverReading> readings;

  @override
  void paint(Canvas canvas, Size size) {
    if (readings.isEmpty) return;

    final linePaint = Paint()
      ..color = const Color(0xFF2389B8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = const Color(0xFF2389B8)
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = const Color(0xFFE5EBEF)
      ..strokeWidth = 1;

    const left = 12.0;
    const right = 12.0;
    const top = 12.0;
    const bottom = 12.0;

    final chartWidth = size.width - left - right;
    final chartHeight = size.height - top - bottom;

    for (var i = 0; i < 3; i++) {
      final y = top + chartHeight * i / 2;
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
    }

    double minLevel = readings.first.waterLevelCm;
    double maxLevel = readings.first.waterLevelCm;

    for (final reading in readings) {
      if (reading.waterLevelCm < minLevel) {
        minLevel = reading.waterLevelCm;
      }
      if (reading.waterLevelCm > maxLevel) {
        maxLevel = reading.waterLevelCm;
      }
    }

    final range = maxLevel - minLevel;
    final safeRange = range == 0 ? 1.0 : range;

    final points = <Offset>[];

    for (var i = 0; i < readings.length; i++) {
      final x = readings.length == 1
          ? size.width / 2
          : left + chartWidth * i / (readings.length - 1);

      final normalized = (readings[i].waterLevelCm - minLevel) / safeRange;

      final y = top + chartHeight * (1 - normalized);

      points.add(Offset(x, y));
    }

    if (points.length > 1) {
      final path = ui.Path()..moveTo(points.first.dx, points.first.dy);

      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }

      canvas.drawPath(path, linePaint);
    }

    for (final point in points) {
      canvas.drawCircle(point, 5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RiverTrendPainter oldDelegate) {
    return oldDelegate.readings != readings;
  }
}
