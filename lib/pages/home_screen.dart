import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../navigation/app_routes.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../widgets/feature_page_shell.dart';
import '../widgets/padang_map.dart';
import '../services/flood_alert_service.dart';
import '../widgets/notification_bell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.account,
    required this.locationService,
    this.apiClient,
  });

  final AuthenticatedUser account;
  final LocationService locationService;
  final ApiClient? apiClient;

  void _open(BuildContext context, String title, String detail) {
    Navigator.of(context).pushNamed(
      AppRoutes.forTitle(title),
      arguments: AppRouteArguments(
        account: account,
        locationService: locationService,
        apiClient: apiClient,
        title: title,
        detail: detail,
        locationName: title == 'Tunggul Hitam' || title == 'Air Tawar'
            ? title
            : null,
        status: switch (title) {
          'Tunggul Hitam' => 'Siaga',
          'Air Tawar' => 'Aman',
          _ => null,
        },
      ),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.profile,
      arguments: AppRouteArguments(
        account: account,
        locationService: locationService,
        apiClient: apiClient,
      ),
    );
  }

  Future<void> _confirmSos(BuildContext context) async {
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi SOS'),
        content: const Text(
          'Apakah kamu ingin melanjutkan? Fitur pengiriman bantuan belum terhubung.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
    if (shouldProceed == true && context.mounted) {
      Navigator.of(context).pushNamed(
        AppRoutes.sos,
        arguments: AppRouteArguments(
          account: account,
          locationService: locationService,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date =
        '${_weekday(now.weekday)}, ${now.day} ${_month(now.month)} ${now.year}';
    final homeTheme = Theme.of(context).copyWith(
      textTheme: Theme.of(context).textTheme
          .apply(fontFamily: 'AtkinsonHyperlegible'),
      primaryTextTheme: Theme.of(context).primaryTextTheme
          .apply(fontFamily: 'AtkinsonHyperlegible'),
    );
    return Theme(
      data: homeTheme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF0B2E3B),
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFF1F6F8),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                Container(
                  height: 124,
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    26,
                    MediaQuery.paddingOf(context).top + 10,
                    20,
                    15,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0B2E3B),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      _HomeProfileAvatar(
                        account: account,
                        apiClient: apiClient,
                        onTap: () => _openProfile(context),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => _openProfile(context),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, ${account.name}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20,
                                ),
                              ),
                              Text(
                                date,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFD2E0E4),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Kalender',
                        onPressed: () => _open(
                          context,
                          'Kalender',
                          'Kalender kesiapsiagaan belum terhubung ke data peringatan.',
                        ),
                        icon: const Icon(
                          Icons.calendar_month_outlined,
                          size: 26,
                        ),
                        color: Colors.white,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      NotificationBell(
                        account: account,
                        onPressed: () => Navigator.of(context).pushNamed(
                          AppRoutes.notifications,
                          arguments: AppRouteArguments(
                            account: account,
                            locationService: locationService,
                            apiClient: apiClient,
                          ),
                        ),
                        backgroundColor: const Color(0xFF0B2E3B),
                        iconSize: 26,
                        buttonSize: 32,
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Menu lainnya',
                        icon: const Icon(Icons.more_vert, size: 21),
                        color: Colors.white,
                        iconColor: Colors.white,
                        padding: EdgeInsets.zero,
                        onSelected: (item) {
                          if (item == 'profil') {
                            _openProfile(context);
                          } else if (item == 'menu') {
                            _open(context, 'Menu', 'Menu aplikasi.');
                          } else {
                            _open(
                              context,
                              'Pengaturan',
                              'Pengaturan aplikasi.',
                            );
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem<String>(
                            value: 'profil',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  color: Color(0xFF0B2E3B),
                                ),
                                SizedBox(width: 10),
                                Text('Profil'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'menu',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.menu_rounded,
                                  color: Color(0xFF0B2E3B),
                                ),
                                SizedBox(width: 10),
                                Text('Menu'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'pengaturan',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.settings_outlined,
                                  color: Color(0xFF0B2E3B),
                                ),
                                SizedBox(width: 10),
                                Text('Pengaturan'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final horizontal = (constraints.maxWidth * .095).clamp(
                        24.0,
                        42.0,
                      );
                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          23,
                          horizontal + 7,
                          12,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _AlertCard(
                                  key: const ValueKey('home-alert-card'),
                                  onTap: (alert) {
                                    if (alert == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Data laporan banjir belum tersedia.',
                                              ),
                                            ),
                                          );
                                      return;
                                    }

                                    Navigator.of(context).pushNamed(
                                      AppRoutes.alert,
                                      arguments: AppRouteArguments(
                                        account: account,
                                        locationService: locationService,
                                        title: 'Status Siaga',
                                        locationName: alert.regionName,
                                        status: alert.status,
                                        selectedAlert: alert,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 18),
                                Padding(
                                  padding: const EdgeInsets.only(left: 3),
                                  child: _WeatherCard(
                                    key: const ValueKey('home-weather-card'),
                                    onTap: () => _open(
                                      context,
                                      'Cuaca',
                                      'Data cuaca aktual belum tersedia karena API cuaca belum terhubung.',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 3,
                                    right: 2,
                                  ),
                                  child: _MapPreview(
                                    key: const ValueKey('home-map-preview'),
                                    onTap: () => _open(
                                      context,
                                      'Peta',
                                      'Peta ilustrasi untuk pratinjau. Data lokasi dan banjir belum terhubung.',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                _MapLegend(),
                                const Padding(
                                  padding: EdgeInsets.zero,
                                  child: Text(
                                    'Pratinjau: status belum real-time.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF71808D),
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 3),
                                  child: _AreaStatus(
                                    key: const ValueKey('home-area-tunggul'),
                                    name: 'Tunggul Hitam',
                                    status: 'Aman',
                                    color: const Color(0xFF2EA361),
                                    onTap: () async {
                                      try {
                                        final alerts = await FloodAlertService()
                                            .fetchAlerts();

                                        final matchingAlerts = alerts.where(
                                          (alert) =>
                                              alert.regionName
                                                  .trim()
                                                  .toLowerCase() ==
                                              'tunggul hitam',
                                        );

                                        if (!context.mounted) return;

                                        if (matchingAlerts.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Data Tunggul Hitam belum tersedia di database.',
                                                  ),
                                                ),
                                              );
                                          return;
                                        }

                                        final alert = matchingAlerts.first;

                                        Navigator.of(context).pushNamed(
                                          AppRoutes.alert,
                                          arguments: AppRouteArguments(
                                            account: account,
                                            locationService: locationService,
                                            title: 'Status Siaga',
                                            locationName: alert.regionName,
                                            status: alert.status,
                                            selectedAlert: alert,
                                          ),
                                        );
                                      } catch (error) {
                                        debugPrint(
                                          'Gagal memuat data Tunggul Hitam: $error',
                                        );

                                        if (!context.mounted) return;

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Gagal mengambil data dari server.',
                                                ),
                                              ),
                                            );
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(height: 9),
                                Padding(
                                  padding: const EdgeInsets.only(left: 3),
                                  child: _AreaStatus(
                                    key: const ValueKey('home-area-air-tawar'),
                                    name: 'Air Tawar',
                                    status: 'Aman',
                                    color: const Color(0xFF2EA361),
                                    onTap: () async {
                                      try {
                                        final alerts = await FloodAlertService()
                                            .fetchAlerts();

                                        final matchingAlerts = alerts.where(
                                          (alert) =>
                                              alert.regionName
                                                  .trim()
                                                  .toLowerCase() ==
                                              'air tawar',
                                        );

                                        if (!context.mounted) return;

                                        if (matchingAlerts.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Data Air Tawar belum tersedia di database.',
                                                  ),
                                                ),
                                              );
                                          return;
                                        }

                                        final alert = matchingAlerts.first;

                                        Navigator.of(context).pushNamed(
                                          AppRoutes.alert,
                                          arguments: AppRouteArguments(
                                            account: account,
                                            locationService: locationService,
                                            title: 'Status Siaga',
                                            locationName: alert.regionName,
                                            status: alert.status,
                                            selectedAlert: alert,
                                          ),
                                        );
                                      } catch (error) {
                                        debugPrint(
                                          'Gagal memuat data Air Tawar: $error',
                                        );

                                        if (!context.mounted) return;

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Gagal mengambil data dari server.',
                                                ),
                                              ),
                                            );
                                      }
                                    },
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Transform.translate(
                                    offset: const Offset(6, 0),
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 13),
                                      child: SizedBox(
                                        height: 54,
                                        width: 125,
                                        child: ElevatedButton(
                                          key: const ValueKey(
                                            'home-sos-button',
                                          ),
                                          onPressed: () => _confirmSos(context),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFFD5282B,
                                            ),
                                            foregroundColor: Colors.white,
                                            elevation: 5,
                                            shape: const StadiumBorder(),
                                            padding: EdgeInsets.zero,
                                          ),
                                          child: const Text(
                                            'SOS',
                                            style: TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                AppMainNavigationBar(
                  activeTab: 'Home',
                  onSelected: (title) {
                    if (title == 'Home') return;
                    _open(context, title, _sectionDetail(title));
                  },
                  token: account.token,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _sectionDetail(String title) => switch (title) {
  'Evakuasi' => 'Informasi rute evakuasi belum terhubung ke peta langsung.',
  'Cuaca' => 'Data cuaca aktual belum terhubung.',
  'Keluarga' =>
    'Daftar keluarga dapat ditambahkan setelah fitur keluarga tersedia.',
  'Kontak' => 'Kontak darurat belum disimpan pada aplikasi.',
  _ => 'Informasi belum tersedia.',
};

String _weekday(int value) => const [
  '',
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
][value];

String _month(int value) => const [
  '',
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
][value];

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      _LegendDot(color: Color(0xFFD62828), label: 'Awas'),
      _LegendDot(color: Color(0xFF987300), label: 'Waspada'),
      _LegendDot(color: Color(0xFFBB6400), label: 'Siaga'),
      _LegendDot(color: Color(0xFF2EA361), label: 'Aman'),
    ],
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

class _AlertCard extends StatefulWidget {
  const _AlertCard({super.key, required this.onTap});

  final ValueChanged<FloodAlert?> onTap;

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard> {
  final FloodAlertService _floodAlertService = FloodAlertService();
  final LocationService _locationService = LocationService();

  List<FloodAlert> _alerts = [];
  bool _loading = true;
  bool _failed = false;
  String _locationLabel = 'Mencari lokasi pengguna...';

  static const double _searchRadiusKm = 3.0;

  @override
  void initState() {
    super.initState();
    _loadAlertsNearUser();
  }

  Future<void> _loadAlertsNearUser() async {
    setState(() {
      _loading = true;
      _failed = false;
      _locationLabel = 'Mencari lokasi pengguna...';
    });

    try {
      final locationResult = await _locationService
          .checkAndGetCurrentPosition();

      if (!mounted) return;

      if (locationResult.status != LocationStatus.available ||
          locationResult.position == null) {
        setState(() {
          _alerts = [];
          _loading = false;
          _locationLabel = 'Lokasi belum tersedia. Aktifkan izin lokasi untuk melihat laporan sekitar.';
        });
        return;
      }

      final userPosition = LatLng(
        locationResult.position!.latitude,
        locationResult.position!.longitude,
      );

      final allAlerts = await _floodAlertService.fetchAlerts();

      final distance = Distance();

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

      if (!mounted) return;

      setState(() {
        _alerts = nearbyAlerts;
        _loading = false;
        _failed = false;
        _locationLabel =
            'Lokasi GPS: ${userPosition.latitude.toStringAsFixed(5)}, '
            '${userPosition.longitude.toStringAsFixed(5)}';
      });
    } catch (error) {
      debugPrint('Gagal memuat laporan sekitar pengguna: $error');

      if (!mounted) return;

      setState(() {
        _alerts = [];
        _loading = false;
        _failed = true;
        _locationLabel = 'Lokasi atau data laporan gagal dimuat.';
      });
    }
  }

  Color _statusColor(String status) {
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

  @override
  Widget build(BuildContext context) {
    final alert = _alerts.isNotEmpty ? _alerts.first : null;
    final color = alert != null ? _statusColor(alert.status) : Colors.blueGrey;

    final measurement = alert?.riseRateCmPerHour == null
        ? 'Data kenaikan air belum tersedia'
        : 'Air naik ${alert!.riseRateCmPerHour!.toStringAsFixed(0)} cm/jam';

    final waterLevelText = alert?.waterLevelCm == null
        ? 'Ketinggian air belum tersedia'
        : 'Tinggi air ${alert!.waterLevelCm!.toStringAsFixed(0)} cm';

    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: const Color(0x300B2E3B),
      borderRadius: BorderRadius.circular(17),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (_loading) return;

          if (alert == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Belum ada laporan banjir dalam radius 3 km dari lokasi Anda.',
                ),
              ),
            );
            return;
          }

          widget.onTap(alert);
        },
        child: SizedBox(
          height: 130,
          child: Row(
            children: [
              Container(
                width: 6,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(17),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _loading
                              ? 'Memuat data...'
                              : _failed
                              ? 'Data tidak tersedia'
                              : alert == null
                              ? 'Belum ada laporan sekitar'
                              : alert.status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _loading
                            ? 'Mencari lokasi dan laporan banjir...'
                            : _failed
                            ? 'Periksa koneksi dan izin lokasi'
                            : alert == null
                            ? 'Belum ada laporan banjir terdekat'
                            : measurement,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _loading
                            ? 'Mohon tunggu'
                            : alert == null
                            ? _locationLabel
                            : '$waterLevelText • ${alert.regionName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                      const Text(
                        'Data laporan perlu diverifikasi.',
                        style: TextStyle(fontSize: 10, color: Colors.blueGrey),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Muat ulang lokasi dan laporan',
                onPressed: _loading ? null : _loadAlertsNearUser,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherCard extends StatefulWidget {
  const _WeatherCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<_WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<_WeatherCard> {
  Map<String, dynamic>? _weather;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      const apiBaseUrl = String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://10.77.170.215:8000/api',
      );

      final response = await http
          .get(Uri.parse('$apiBaseUrl/weather'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Gagal mengambil data cuaca');
      }

      final result = jsonDecode(response.body) as Map<String, dynamic>;

      if (result['temperature_c'] == null || result['description'] == null) {
        throw Exception('Data cuaca tidak lengkap');
      }

      if (!mounted) return;

      setState(() {
        _weather = result;
        _loading = false;
        _failed = false;
      });
    } catch (e) {
      debugPrint('Gagal memuat cuaca BMKG: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) => _TapCard(
    onTap: widget.onTap,
    child: SizedBox(
      height: 66,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cuaca saat ini', style: TextStyle(fontSize: 16)),
            Text(
              _loading
                  ? 'Mengambil data BMKG...'
                  : _failed
                  ? 'Data BMKG belum tersedia'
                  : '${_weather!['description']}'
                        ', ${_weather!['temperature_c']}°C',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MapPreview extends StatefulWidget {
  const _MapPreview({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<_MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<_MapPreview> {
  final FloodAlertService _floodAlertService = FloodAlertService();

  List<FloodAlert> _alerts = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final alerts = await _floodAlertService.fetchAlerts();

      if (!mounted) return;

      setState(() {
        _alerts = alerts;
      });
    } catch (error) {
      debugPrint('Gagal memuat marker banjir di Home: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE9F2F4),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: SizedBox(
          height: 182,
          child: IgnorePointer(
            child: PadangMap(height: 182, floodAlerts: _alerts),
          ),
        ),
      ),
    );
  }
}

class _AreaStatus extends StatelessWidget {
  const _AreaStatus({
    super.key,
    required this.name,
    required this.status,
    required this.color,
    required this.onTap,
  });
  final String name;
  final String status;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _TapCard(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9.5),
    child: Row(
      children: [
        Expanded(child: Text(name, style: const TextStyle(fontSize: 16))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _TapCard extends StatelessWidget {
  const _TapCard({required this.onTap, required this.child, this.padding});
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 2,
    shadowColor: const Color(0x300B2E3B),
    borderRadius: BorderRadius.circular(17),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    ),
  );
}

class _HomeProfileAvatar extends StatefulWidget {
  const _HomeProfileAvatar({
    required this.account,
    required this.apiClient,
    required this.onTap,
  });

  final AuthenticatedUser account;
  final ApiClient? apiClient;
  final VoidCallback onTap;

  @override
  State<_HomeProfileAvatar> createState() => _HomeProfileAvatarState();
}

class _HomeProfileAvatarState extends State<_HomeProfileAvatar> {
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    final client = widget.apiClient;
    if (client == null) return;

    try {
      final profile = await client.getProfile(token: widget.account.token);

      final path = profile.profilePhotoPath;

      if (path == null || path.trim().isEmpty) return;

      final serverUrl = client.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

      if (!mounted) return;

      setState(() {
        _photoUrl =
            '$serverUrl/storage/${path.replaceFirst(RegExp(r'^/+'), '')}';
      });
    } catch (error) {
      debugPrint('Gagal memuat foto profil di Home: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.account.name.trim().isEmpty
        ? '?'
        : widget.account.name.trim()[0].toUpperCase();

    return InkWell(
      onTap: widget.onTap,
      customBorder: const CircleBorder(),
      child: CircleAvatar(
        radius: 33,
        backgroundColor: const Color(0xFF118AA1),
        child: ClipOval(
          child: SizedBox(
            width: 66,
            height: 66,
            child: _photoUrl == null
                ? Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : Image.network(
                    _photoUrl!,
                    fit: BoxFit.cover,
                    webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
