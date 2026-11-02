import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/evacuation_point.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../widgets/feature_page_shell.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EvacuationScreen extends StatefulWidget {
  const EvacuationScreen({
    super.key,
    required this.account,
    required this.locationService,
  });

  final AuthenticatedUser account;
  final LocationService locationService;

  @override
  State<EvacuationScreen> createState() => _EvacuationScreenState();
}

class _EvacuationScreenState extends State<EvacuationScreen> {
  Future<void> _openRoute(EvacuationPoint point) async {
    // Ambil lokasi pengguna jika belum tersedia.
    if (_currentPosition == null) {
      await _getCurrentLocation();
    }

    final currentPosition = _currentPosition;

    if (!mounted || currentPosition == null) {
      return;
    }

    // Buat alamat Google Maps Directions.
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${currentPosition.latitude},${currentPosition.longitude}'
      '&destination=${point.latitude},${point.longitude}'
      '&travelmode=driving',
    );

    try {
      final opened = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google Maps tidak dapat dibuka.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membuka Google Maps.'),
        ),
      );
    }
  }
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  final ApiClient _apiClient = ApiClient();
  final MapController _mapController = MapController();

  List<EvacuationPoint> _points = [];
  bool _isLoading = true;
  String? _errorMessage;
  Position? _currentPosition;
  bool _isGettingLocation = false;
  int? _selectedPointId;

  List<EvacuationPoint> get _validPoints => _points.where((point) {
        return point.latitude >= -90 &&
            point.latitude <= 90 &&
            point.longitude >= -180 &&
            point.longitude <= 180;
      }).toList();

  double? _distanceTo(EvacuationPoint point) {
    final position = _currentPosition;
    if (position == null) return null;
    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      point.latitude,
      point.longitude,
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  List<EvacuationPoint> get _pointsByDistance {
    final points = [..._validPoints];
    if (_currentPosition == null) return points;
    points.sort((a, b) {
      return (_distanceTo(a) ?? double.infinity)
          .compareTo(_distanceTo(b) ?? double.infinity);
    });
    return points;
  }

  Future<void> _getCurrentLocation() async {
    if (_isGettingLocation) return;
    setState(() => _isGettingLocation = true);

    final result = await widget.locationService.checkAndGetCurrentPosition();
    if (!mounted) return;

    setState(() {
      _isGettingLocation = false;
      if (result.status == LocationStatus.available &&
          result.position != null) {
        _currentPosition = result.position;
      }
    });

    if (result.status == LocationStatus.available &&
        result.position != null) {
      _mapController.move(
        LatLng(result.position!.latitude, result.position!.longitude),
        14,
      );
      return;
    }

    final message = switch (result.status) {
      LocationStatus.permissionDenied =>
        'Izin lokasi ditolak. Izinkan akses lokasi untuk menemukan posisi Anda.',
      LocationStatus.permissionDeniedForever =>
        'Izin lokasi diblokir. Aktifkan melalui pengaturan browser atau perangkat.',
      LocationStatus.serviceDisabled =>
        'Layanan lokasi belum aktif. Aktifkan lokasi perangkat.',
      _ => result.message ?? 'Lokasi belum berhasil ditemukan. Coba lagi.',
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  Future<void> _loadEvacuationPoints() async {
    try {
      final points = await _apiClient.fetchEvacuationPoints(
        token: widget.account.token,
      );
      if (!mounted) return;
      setState(() {
        _points = points;
        _isLoading = false;
        _errorMessage = null;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan saat memuat data pengungsian.';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadEvacuationPoints();
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final points = _validPoints;
    final orderedPoints = _pointsByDistance;
    EvacuationPoint? selectedPoint;
    for (final point in points) {
      if (point.id == _selectedPointId) {
        selectedPoint = point;
        break;
      }
    }
    final nearestPoint = orderedPoints.isEmpty ? null : orderedPoints.first;

    return FeaturePageShell(
      title: 'Evakuasi',
      account: widget.account,
      locationService: widget.locationService,
      activeTab: 'Evakuasi',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = (constraints.maxWidth * .095).clamp(
            24.0,
            42.0,
          );

          return ListView(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              23,
              horizontal + 7,
              110,
            ),
        children: [
          _sectionTitle('Peta Lokasi Pengungsian'),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 190,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: points.isNotEmpty
                          ? LatLng(points.first.latitude, points.first.longitude)
                          : const LatLng(-0.9471, 100.4172),
                      initialZoom: 12,
                      onTap: (_, _) => setState(() => _selectedPointId = null),
                    ),
                    children: [
                      // 1. Peta dasar OpenStreetMap
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.siagabanjir.app',
                      ),

                      // 2. Garis rute berwarna biru
                      if (_routePoints.length >= 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              strokeWidth: 5,
                              color: Colors.blue,
                            ),
                          ],
                        ),

                      // 3. Penanda titik pengungsian
                      MarkerLayer(
                        markers: points.map((point) {
                          final selected = _selectedPointId == point.id;

                          return Marker(
                            point: LatLng(
                              point.latitude,
                              point.longitude,
                            ),
                            width: 44,
                            height: 44,
                            child: GestureDetector(
                              onTap: () => _loadRoute(point),
                              child: Icon(
                                Icons.location_on,
                                size: 40,
                                color: selected
                                    ? Colors.orange
                                    : const Color(0xFF12809A),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // 4. Penanda lokasi pengguna
                      if (_currentPosition != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              width: 42,
                              height: 42,
                              child: const Icon(
                                Icons.my_location,
                                color: Color(0xFF1688F8),
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      elevation: 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _isGettingLocation ? null : _getCurrentLocation,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isGettingLocation)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.my_location,
                                  size: 14,
                                  color: Color(0xFF244B5A),
                                ),
                              const SizedBox(width: 5),
                              Text(
                                _isGettingLocation
                                    ? 'Mencari...'
                                    : 'Lokasi Saya',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF244B5A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (selectedPoint != null) ...[
            const SizedBox(height: 8),
            _selectedLocationCard(selectedPoint),
          ],
          const SizedBox(height: 16),
          _sectionTitle('Informasi Jalan'),
          const SizedBox(height: 7),
          _infoRow(
            title: 'Kondisi jalan',
            value: 'Belum tersedia',
            color: const Color(0xFF8A6A16),
          ),
          const SizedBox(height: 7),
          _infoRow(
            title: 'Pembaruan informasi',
            value: 'Menunggu data',
            color: const Color(0xFF657680),
          ),
          const SizedBox(height: 16),
          _sectionTitle(
            _currentPosition == null
                ? 'Titik Pengungsian'
                : 'Titik Pengungsian Terdekat',
          ),
          const SizedBox(height: 7),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(22),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            _messageCard(
              icon: Icons.cloud_off,
              message: _errorMessage!,
              action: TextButton(
                onPressed: _loadEvacuationPoints,
                child: const Text('Coba lagi'),
              ),
            )
          else if (orderedPoints.isEmpty)
            _messageCard(
              icon: Icons.location_off,
              message: 'Belum ada titik pengungsian yang tersedia.',
            )
          else
            ...orderedPoints.take(3).map((point) {
              final distance = _distanceTo(point);
              return Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: _nearbyPointRow(
                  point: point,
                  distance: distance,
                  selected: point.id == _selectedPointId,
                ),
              );
            }),
            if (nearestPoint != null && !_isLoading && _errorMessage == null) ...[
              const SizedBox(height: 7),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoadingRoute
                      ? null
                      : () {
                          if (_selectedPointId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Pilih titik pengungsian terlebih dahulu.',
                                ),
                              ),
                            );
                            return;
                          }

                          final selectedPoint = _points.firstWhere(
                            (point) => point.id == _selectedPointId,
                          );

                          _openRoute(selectedPoint);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF087E91),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoadingRoute
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Mulai rute',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          const SizedBox(height: 12),
          const Text(
            'Informasi lokasi berasal dari server SiagaBanjir. '
            'Kondisi jalan belum tersedia dan lokasi uji belum terverifikasi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF71808D),
              fontSize: 10,
              ),
          ),
        ],
      );
        },
      ),
    );
  }
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF0B2E3B),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _infoRow({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E9EC)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF40535C),
                fontSize: 11,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nearbyPointRow({
    required EvacuationPoint point,
    required double? distance,
    required bool selected,
  }) {
    final isTestData = (point.description ?? '').toUpperCase().contains('DATA UJI');
    return Material(
      color: selected ? const Color(0xFFE5F5F5) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _loadRoute(point);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF12809A)
                  : const Color(0xFFE1E9EC),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 19,
                color: Color(0xFF12809A),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF173744),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isTestData)
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          'Data uji · belum terverifikasi',
                          style: TextStyle(
                            color: Color(0xFF8A6A16),
                            fontSize: 9,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                distance == null ? 'Pilih lokasi' : _formatDistance(distance),
                style: const TextStyle(
                  color: Color(0xFF173744),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectedLocationCard(EvacuationPoint point) {
    final distance = _distanceTo(point);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE7EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            point.name,
            style: const TextStyle(
              color: Color(0xFF173744),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (point.address != null && point.address!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                point.address!,
                style: const TextStyle(
                  color: Color(0xFF657680),
                  fontSize: 10,
                ),
              ),
            ),
          if (distance != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                'Jarak garis lurus: ${_formatDistance(distance)}',
                style: const TextStyle(
                  color: Color(0xFF657680),
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String message,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E9EC)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF71808D), size: 28),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
          ?action,
        ],
      ),
    );
  }
  Future<void> _loadRoute(EvacuationPoint point) async {
  // Ambil lokasi pengguna jika belum tersedia.
  if (_currentPosition == null) {
    await _getCurrentLocation();
  }

  final currentPosition = _currentPosition;

  if (!mounted || currentPosition == null) {
    return;
  }

  setState(() {
    _selectedPointId = point.id;
    _isLoadingRoute = true;
    _routePoints = [];
  });

  try {
    // Meminta rute berkendara dari layanan OSRM.
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${currentPosition.longitude},${currentPosition.latitude};'
      '${point.longitude},${point.latitude}'
      '?overview=full&geometries=geojson',
    );

    final response = await http.get(url).timeout(
      const Duration(seconds: 20),
    );

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil jalur.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data['code'] != 'Ok') {
      throw Exception('Rute tidak ditemukan.');
    }

    final routes = data['routes'] as List<dynamic>;

    if (routes.isEmpty) {
      throw Exception('Rute tidak tersedia.');
    }

    final geometry =
        routes.first['geometry'] as Map<String, dynamic>;

    final coordinates = geometry['coordinates'] as List<dynamic>;

    // GeoJSON menyimpan koordinat dengan urutan longitude, latitude.
    final routePoints = coordinates.map((coordinate) {
      final values = coordinate as List<dynamic>;

      return LatLng(
        (values[1] as num).toDouble(),
        (values[0] as num).toDouble(),
      );
    }).toList();

    if (!mounted) return;

    if (routePoints.length < 2) {
      throw Exception('Jalur tidak memiliki cukup titik.');
    }

    setState(() {
      _routePoints = routePoints;
      _isLoadingRoute = false;
    });

    // Tampilkan seluruh rute di dalam area peta.
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: routePoints,
        padding: const EdgeInsets.all(35),
      ),
    );
  } catch (error) {
    if (!mounted) return;

    setState(() {
      _isLoadingRoute = false;
      _routePoints = [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Rute gagal dimuat. Periksa koneksi internet dan lokasi Anda.',
        ),
      ),
    );
  }
}
}
