import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_client.dart';
import '../services/flood_alert_service.dart';
import '../services/location_service.dart';
import '../widgets/feature_page_shell.dart';
import '../widgets/padang_map.dart';
import '../widgets/reference_components.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.account,
    required this.locationService,
  });

  final AuthenticatedUser account;
  final LocationService locationService;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  bool _loading = false;
  String? _locationMessage;
  LatLng? _userPosition;

  final FloodAlertService _floodAlertService = FloodAlertService();

  bool _loadingFloodAlerts = false;
  String? _floodAlertError;
  List<FloodAlert> _floodAlerts = [];

  @override
  void initState() {
    super.initState();
    _loadFloodAlerts();
  }


  Future<void> _getLocation() async {
    setState(() {
      _loading = true;
      _locationMessage = null;
    });

    final result =
        await widget.locationService.checkAndGetCurrentPosition();

    if (!mounted) return;

    setState(() {
      _loading = false;

      if (result.status == LocationStatus.available) {
        final position = result.position!;

        _userPosition = LatLng(
          position.latitude,
          position.longitude,
        );

        _locationMessage =
            'Lokasi berhasil ditemukan: '
            '${position.latitude.toStringAsFixed(5)}, '
            '${position.longitude.toStringAsFixed(5)}.';
      } else {
        _locationMessage = switch (result.status) {
          LocationStatus.available => null,
          LocationStatus.permissionDenied =>
            'Izin lokasi ditolak. Izinkan lokasi untuk melanjutkan.',
          LocationStatus.permissionDeniedForever =>
            'Izin lokasi ditolak permanen. Aktifkan melalui Pengaturan aplikasi.',
          LocationStatus.serviceDisabled =>
            'GPS/lokasi perangkat nonaktif. Aktifkan layanan lokasi lalu coba lagi.',
          LocationStatus.failed =>
            result.message ?? 'Lokasi gagal diperoleh.',
        };
      }
    });

    if (result.status == LocationStatus.available &&
        _userPosition != null) {
      _mapController.move(_userPosition!, 15);
    }

    if (result.status == LocationStatus.permissionDeniedForever &&
        mounted) {
      final open = await _askToOpenSettings(
        title: 'Izin lokasi dibutuhkan',
        message:
            'Buka Pengaturan aplikasi dan aktifkan Lokasi saat aplikasi digunakan.',
        action: 'Pengaturan aplikasi',
      );

      if (open && mounted) {
        await widget.locationService.openAppSettings();
      }
    } else if (result.status == LocationStatus.serviceDisabled &&
        mounted) {
      final open = await _askToOpenSettings(
        title: 'Lokasi perangkat nonaktif',
        message: 'Aktifkan GPS/lokasi pada pengaturan perangkat.',
        action: 'Pengaturan lokasi',
      );

      if (open && mounted) {
        await widget.locationService.openLocationSettings();
      }
    }
  }
    Future<void> _loadFloodAlerts() async {
    setState(() {
      _loadingFloodAlerts = true;
      _floodAlertError = null;
    });
    
    try {
      final alerts = await _floodAlertService.fetchAlerts();

      if (!mounted) return;

      setState(() {
        _floodAlerts = alerts;
        _loadingFloodAlerts = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadingFloodAlerts = false;
        _floodAlertError = 'Data banjir gagal dimuat: $error';
      });
    }
  }
  Future<bool> _askToOpenSettings({
    required String title,
    required String message,
    required String action,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Nanti'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) => FeaturePageShell(
        title: 'Peta',
        account: widget.account,
        locationService: widget.locationService,
        activeTab: 'Home',
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            PadangMap(
              height: 330,
              controller: _mapController,
              showUserMarker: _userPosition != null,
              userPosition: _userPosition,
              floodAlerts: _floodAlerts,
            ),

            // Status pemuatan data banjir.
            if (_loadingFloodAlerts) ...[
              const SizedBox(height: 12),
              const Center(
                child: CircularProgressIndicator(),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text('Memuat data banjir...'),
              ),
            ] else if (_floodAlertError != null) ...[
              const SizedBox(height: 12),
              ReferenceCard(
                child: Text(
                  _floodAlertError!,
                  style: const TextStyle(
                    color: Colors.red,
                    height: 1.4,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _loadFloodAlerts,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba muat ulang'),
              ),
            ] else if (_floodAlerts.isEmpty) ...[
              const SizedBox(height: 12),
              const ReferenceCard(
                child: Text(
                  'Belum ada data banjir aktif dari server.',
                  style: TextStyle(
                    color: Color(0xFF71808D),
                    height: 1.4,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _LegendDot(color: Color(0xFFD62828), label: 'Awas'),
                _LegendDot(color: Color(0xFF987300), label: 'Waspada'),
                _LegendDot(color: Color(0xFFBB6400), label: 'Siaga'),
                _LegendDot(color: Color(0xFF2EA361), label: 'Aman'),
              ],
            ),
            const SizedBox(height: 14),

            // Tombol untuk mengambil lokasi pengguna.
            FilledButton.icon(
              onPressed: _loading ? null : _getLocation,
              icon: _loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                _loading ? 'Mencari lokasi…' : 'Gunakan lokasi saya',
              ),
            ),

            if (_locationMessage != null) ...[
              const SizedBox(height: 12),
              ReferenceCard(
                child: Text(
                  _locationMessage!,
                  style: const TextStyle(
                    color: Color(0xFF0B2E3B),
                    height: 1.4,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),
            const Text(
              'Peta menampilkan wilayah Kota Padang. Data banjir berasal '
              'dari server dan perlu diverifikasi sebelum dianggap sebagai '
              'informasi kejadian aktual.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF71808D),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
}
class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}
