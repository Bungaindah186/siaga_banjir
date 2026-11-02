import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';
import '../services/api_client.dart';
import '../services/flood_alert_service.dart';
import '../services/location_service.dart';
import '../widgets/feature_page_shell.dart';
import '../widgets/reference_components.dart';

class AlertDetailScreen extends StatefulWidget {
  const AlertDetailScreen({
    super.key,
    required this.account,
    required this.locationService,
    this.locationName,
    this.status,
    this.selectedAlert,
  });

  final AuthenticatedUser account;
  final LocationService locationService;
  final String? locationName;
  final String? status;
  final FloodAlert? selectedAlert;

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  final _done = <bool>[true, false, false];
  final _alertService = FloodAlertService();

  late Future<List<FloodAlert>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _alertsFuture = _alertService.fetchAlerts();
  }

  Future<void> _refreshAlerts() async {
    final future = _alertService.fetchAlerts();

    setState(() {
      _alertsFuture = future;
    });

    await future;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aman':
        return const Color(0xFF2EA361);
      case 'siaga':
        return const Color(0xFFBB6400);
      case 'awas':
        return const Color(0xFFC8282B);
      case 'waspada':
        return const Color(0xFF987300);
      default:
        return const Color(0xFF666666);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeaturePageShell(
      title: 'Status Siaga',
      account: widget.account,
      locationService: widget.locationService,
      activeTab: 'Home',
      child: FutureBuilder<List<FloodAlert>>(
        future: _alertsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Data peringatan belum dapat dimuat.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _refreshAlerts,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final alerts = snapshot.data ?? [];

          if (alerts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Belum ada data peringatan banjir.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _refreshAlerts,
                      child: const Text('Muat ulang'),
                    ),
                  ],
                ),
              ),
            );
          }

          // API mengurutkan laporan terbaru terlebih dahulu.
          // Halaman ini menggunakan laporan terbaru yang tersedia.
          final alert = widget.selectedAlert ?? alerts.first;
          final statusColor = _statusColor(alert.status);

          final waterLevel = alert.waterLevelCm;
          final riseRate = alert.riseRateCmPerHour;

          return RefreshIndicator(
            onRefresh: _refreshAlerts,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 100),
              children: [
                ReferenceCard(
                  padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 5,
                        height: 84,
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ReferenceStatusPill(
                              label: alert.status.isEmpty
                                  ? 'Status belum diketahui'
                                  : alert.status,
                              color: statusColor,
                              icon: Icons.warning_rounded,
                            ),
                            const SizedBox(height: 7),
                            Text(
                              riseRate == null
                                  ? alert.title
                                  : 'Ketinggian air naik '
                                      '${riseRate.toStringAsFixed(0)} cm/jam',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${alert.regionName}'
                              '${waterLevel == null ? '' : ' • Tinggi air ${waterLevel.toStringAsFixed(0)} cm'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (alert.description.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                alert.description,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                ReferenceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ReferenceSectionHeading(
                        'Yang perlu dilakukan sekarang',
                      ),
                      const SizedBox(height: 4),
                      for (var i = 0; i < _actions.length; i++)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(_actions[i]),
                          value: _done[i],
                          activeColor: const Color(0xFF12809A),
                          onChanged: (value) {
                            setState(() {
                              _done[i] = value ?? false;
                            });
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const ReferenceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ReferenceSectionHeading('Arti level'),
                      Text('Aman → Waspada → Siaga → Awas.'),
                      Text('Awas berarti segera evakuasi.'),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 9, 4, 18),
                  child: Text(
                    'Jika level banjir naik, segera lakukan evakuasi ke tempat aman. '
                    'Jika level banjir turun, tetap waspada dan pantau informasi terbaru.',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(
                  height: 56,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF0B2E3B),
                          Color(0xFF12809A),
                        ],
                      ),
                      borderRadius: BorderRadius.all(
                        Radius.circular(30),
                      ),
                    ),
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.evacuation,
                        arguments: AppRouteArguments(
                          account: widget.account,
                          locationService: widget.locationService,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      child: const Text(
                        'Lihat rute evakuasi',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

const _actions = [
  'Siapkan tas siaga',
  'Pindahkan barang ke tempat tinggi',
  'Kabari keluarga',
];