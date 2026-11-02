import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

import '../services/api_client.dart';
import '../services/location_service.dart';
import '../widgets/feature_page_shell.dart';

class HomeLocationPickerScreen extends StatefulWidget {
  const HomeLocationPickerScreen({
    super.key,
    required this.account,
    required this.locationService,
    required this.apiClient,
  });

  final AuthenticatedUser account;
  final LocationService locationService;
  final ApiClient apiClient;

  @override
  State<HomeLocationPickerScreen> createState() =>
      _HomeLocationPickerScreenState();
}

class _HomeLocationPickerScreenState extends State<HomeLocationPickerScreen> {
  static const LatLng _padangCenter = LatLng(-0.9471, 100.4172);

  final MapController _mapController = MapController();

  LatLng? _selectedPosition;
  bool _loadingProfile = true;
  bool _savingLocation = false;

  String? _selectedAddress;
  bool _loadingAddress = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
  }

  Future<void> _loadSavedLocation() async {
    try {
      final profile = await widget.apiClient.getProfile(
        token: widget.account.token,
      );

      if (!mounted) return;

      final latitude = profile.homeLatitude;
      final longitude = profile.homeLongitude;

      if (latitude != null && longitude != null) {
        final savedPosition = LatLng(latitude, longitude);

        setState(() {
          _selectedPosition = savedPosition;
          _loadingProfile = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.move(savedPosition, 16);
          }
        });
      } else {
        setState(() {
          _loadingProfile = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingProfile = false;
      });

      _showMessage('Gagal memuat lokasi rumah: $e');
    }
  }

  Future<void> _selectLocation(TapPosition tapPosition, LatLng position) async {
    setState(() {
      _selectedPosition = position;
      _selectedAddress = null;
      _loadingAddress = true;
    });

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': position.latitude.toString(),
        'lon': position.longitude.toString(),
        'format': 'jsonv2',
        'addressdetails': '1',
        'accept-language': 'id',
      });

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'SiagaBanjirPadang/1.0'},
      );

      if (response.statusCode != 200) {
        throw Exception('Layanan pencarian alamat tidak tersedia.');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final address = data['display_name'] as String?;

      if (!mounted || _selectedPosition != position) return;

      setState(() {
        _selectedAddress = address ?? 'Alamat tidak ditemukan.';
        _loadingAddress = false;
      });
    } catch (e) {
      if (!mounted || _selectedPosition != position) return;

      setState(() {
        _selectedAddress = 'Alamat gagal ditemukan. Silakan isi manual.';
        _loadingAddress = false;
      });
    }
  }

  Future<void> _saveLocation() async {
    final position = _selectedPosition;

    if (position == null) {
      _showMessage('Pilih titik lokasi rumah pada peta terlebih dahulu.');
      return;
    }

    if (_loadingAddress) {
      _showMessage('Tunggu sampai pencarian alamat selesai.');
      return;
    }

    setState(() {
      _savingLocation = true;
    });

    try {
      await widget.apiClient.updateProfile(
        token: widget.account.token,
        homeLatitude: position.latitude,
        homeLongitude: position.longitude,
        homeAddress: _selectedAddress,
      );

      if (!mounted) return;

      _showMessage('Alamat dan koordinat rumah berhasil disimpan.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      _showMessage('Gagal menyimpan lokasi rumah: $e');
    } finally {
      if (mounted) {
        setState(() {
          _savingLocation = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final position = _selectedPosition;

    return FeaturePageShell(
      title: 'Lokasi Rumah',
      account: widget.account,
      locationService: widget.locationService,
      activeTab: 'Home',
      showTopActions: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          const Text(
            'Tentukan Lokasi Rumah',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B2E3B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ketuk titik pada peta yang menunjukkan lokasi rumahmu. '
            'Kamu bisa menggeser peta untuk mencari lokasi yang tepat.',
            style: TextStyle(color: Color(0xFF71808D), height: 1.5),
          ),
          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 420,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _padangCenter,
                  initialZoom: 12,
                  minZoom: 9,
                  maxZoom: 19,
                  onTap: _selectLocation,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.siagabanjir.app',
                    maxNativeZoom: 19,
                  ),
                  if (position != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: position,
                          width: 50,
                          height: 50,
                          child: const Icon(
                            Icons.location_on,
                            color: Color(0xFFC8282B),
                            size: 46,
                          ),
                        ),
                      ],
                    ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('© OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          if (_loadingAddress)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Mencari alamat lokasi...'),
                  ],
                ),
              ),
            )
          else if (_selectedAddress != null)
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alamat Rumah',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_selectedAddress!),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          if (_loadingProfile)
            const Center(child: CircularProgressIndicator())
          else if (position == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'Belum ada lokasi rumah tersimpan. '
                  'Ketuk peta untuk memilih lokasi.',
                  style: TextStyle(color: Color(0xFF71808D)),
                ),
              ),
            )
          else
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: Color(0xFF12809A)),
                        SizedBox(width: 8),
                        Text(
                          'Titik lokasi terpilih',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Latitude: ${position.latitude.toStringAsFixed(7)}'),
                    Text('Longitude: ${position.longitude.toStringAsFixed(7)}'),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _savingLocation || _loadingProfile || position == null
                  ? null
                  : _saveLocation,
              icon: _savingLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_savingLocation ? 'Menyimpan...' : 'Simpan Lokasi'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF12809A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
