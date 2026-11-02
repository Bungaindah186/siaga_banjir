import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/flood_alert_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PadangMap extends StatelessWidget {
  const PadangMap({
    super.key,
    this.height = 330,
    this.showUserMarker = false,
    this.userPosition,
    this.controller,
    this.floodAlerts = const [],
  });

  final double height;
  final bool showUserMarker;
  final LatLng? userPosition;
  final MapController? controller;
  final List<FloodAlert> floodAlerts;

  static const LatLng padangCenter = LatLng(-0.9471, 100.4172);

Future<void> _openGoogleMaps({
  required double latitude,
  required double longitude,
}) async {
  final Uri url = Uri.https(
    'www.google.com',
    '/maps/dir/',
    {
      'api': '1',
      'destination': '$latitude,$longitude',
      'travelmode': 'driving',
    },
  );

  try {
    final bool success = await launchUrl(
      url,
      webOnlyWindowName: '_self',
    );

    if (!success) {
      debugPrint('Google Maps gagal dibuka: $url');
    }
  } catch (e) {
    debugPrint('Error membuka Google Maps: $e');
  }
}

// DATA CONTOH SAJA, BUKAN DAFTAR TEMPAT EVAKUASI RESMI.
static const List<_EvacuationPoint> _evacuationPoints = [
  _EvacuationPoint(
    name: 'Pos Evakuasi Contoh 1',
    area: 'Wilayah Kota Padang',
    position: LatLng(-0.9550, 100.3950),
    description: 'Lokasi demonstrasi tempat evakuasi.',
  ),
  _EvacuationPoint(
    name: 'Pos Evakuasi Contoh 2',
    area: 'Wilayah Kota Padang',
    position: LatLng(-0.9100, 100.4100),
    description: 'Lokasi demonstrasi tempat evakuasi.',
  ),
];  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'awas':
        return const Color(0xFFD62828);
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

  void _showApiFloodInfo(
    BuildContext context,
    FloodAlert alert,
    Color color,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.water_drop, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(alert.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wilayah: ${alert.regionName}'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Status: '),
                Text(
                  alert.status,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              alert.description.isEmpty
                  ? 'Tidak ada deskripsi laporan.'
                  : alert.description,
            ),
            const SizedBox(height: 12),
            const Text(
              'Periksa sumber laporan sebelum menjadikannya acuan keselamatan.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              _openGoogleMaps(
                latitude: alert.position!.latitude,
                longitude: alert.position!.longitude,
              );
            },
            icon: const Icon(Icons.directions),
            label: const Text('Buka Google Maps'),
          ),
        ],
      ),
    );
  }

void _showEvacuationInfo(
  BuildContext context,
  _EvacuationPoint point,
) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.home, color: Colors.green),
          SizedBox(width: 8),
          Expanded(child: Text('Tempat Evakuasi')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            point.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Wilayah: ${point.area}'),
          const SizedBox(height: 8),
          Text(point.description),
          const SizedBox(height: 12),
          const Text(
            'Data demonstrasi — bukan lokasi evakuasi resmi.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Tutup'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            _openGoogleMaps(
              latitude: point.position.latitude,
              longitude: point.position.longitude,
            );
          },
          icon: const Icon(Icons.directions),
          label: const Text('Buka Google Maps'),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          mapController: controller,
          options: const MapOptions(
            initialCenter: padangCenter,
            initialZoom: 12,
            minZoom: 9,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.siagabanjir.app',
              maxNativeZoom: 19,
            ),

            // Titik banjir dari API Laravel.
            MarkerLayer(
              markers: floodAlerts
                  .where((alert) => alert.position != null)
                  .map((alert) {
                final color = _statusColor(alert.status);

                return Marker(
                  point: alert.position!,
                  width: 48,
                  height: 48,
                  child: GestureDetector(
                    onTap: () => _showApiFloodInfo(
                      context,
                      alert,
                      color,
                    ),
                    onLongPress: () => _openGoogleMaps(
                      latitude: alert.position!.latitude,
                      longitude: alert.position!.longitude,
                      ),
                    child: Tooltip(
                      message: '${alert.title} - ${alert.status}',
                      child: Icon(
                        Icons.location_on,
                        color: color,
                        size: 42,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            // Titik tempat evakuasi contoh.
            MarkerLayer(
              markers: _evacuationPoints.map((point) {
                return Marker(
                  point: point.position,
                  width: 48,
                  height: 48,
                  child: GestureDetector(
                    onTap: () => _showEvacuationInfo(context, point),
                    onLongPress: () => _openGoogleMaps(
                      latitude: point.position.latitude,
                      longitude: point.position.longitude,
                    ),
                    child: const Tooltip(
                      message: 'Tekan untuk informasi, tahan untuk membuka rute di Google Maps',
                      child: Icon(
                        Icons.home,
                        color: Colors.green,
                        size: 36,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            // Penanda lokasi pengguna.
            if (showUserMarker && userPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: userPosition!,
                    width: 44,
                    height: 44,
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 34,
                    ),
                  ),
                ],
              ),

            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  '© OpenStreetMap contributors',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EvacuationPoint {
  const _EvacuationPoint({
    required this.name,
    required this.area,
    required this.position,
    required this.description,
  });

  final String name;
  final String area;
  final LatLng position;
  final String description;
}