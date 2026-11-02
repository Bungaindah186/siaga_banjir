import 'dart:async';

import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../widgets/feature_page_shell.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.account,
    required this.locationService,
  });

  final AuthenticatedUser account;
  final LocationService locationService;

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {
  late final NotificationService _service;
  Timer? _timer;

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _loading = true;
  final bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _service = NotificationService(
      apiClient: ApiClient(),
      token: widget.account.token,
    );

    _loadNotifications();

    // Memeriksa notifikasi baru setiap 10 detik
    // selama halaman notifikasi terbuka.
    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadNotifications(silent: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications({
    bool silent = false,
  }) async {
    if (_busy && !silent) return;

    try {
      final result = await _service.getNotifications();

      if (!mounted) return;

      setState(() {
        _notifications = result.notifications;
        _unreadCount = result.unreadCount;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _markAsRead(AppNotification item) async {
    if (item.isRead) return;

    try {
      await _service.markAsRead(item.id);
      await _loadNotifications(silent: true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menandai notifikasi: $error')),
      );
    }
  }

  Future<void> _deleteNotification(
    AppNotification item,
  ) async {
    try {
      await _service.deleteNotification(item.id);
      await _loadNotifications(silent: true);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifikasi berhasil dihapus.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus notifikasi: $error')),
      );
    }
  }

  Future<void> _deleteAll() async {
    if (_notifications.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus semua notifikasi?'),
        content: const Text(
          'Semua notifikasi akan dihapus dari akunmu. '
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus semua'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _service.deleteAllNotifications();
      await _loadNotifications(silent: true);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua notifikasi berhasil dihapus.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus notifikasi: $error')),
      );
    }
  }

  Future<void> _openNotification(
    AppNotification item,
  ) async {
    await _markAsRead(item);

    if (!mounted) return;

    final arguments = AppRouteArguments(
      account: widget.account,
      locationService: widget.locationService,
    );

    final type = item.type.trim().toLowerCase();
    final title = item.title.trim().toLowerCase();
    final message = item.message.trim().toLowerCase();
    final content = '$title $message';

    String? targetRoute;

    switch (type) {
      case 'flood_alert':
        targetRoute = AppRoutes.alert;
        break;

      case 'weather':
        targetRoute = AppRoutes.weather;
        break;

      case 'river_height':
        targetRoute = AppRoutes.riverHeight;
        break;

      case 'evacuation':
        targetRoute = AppRoutes.evacuation;
        break;

      case 'emergency_bag':
      case 'emergency_bag_preparation':
        targetRoute = AppRoutes.emergencyBag;
        break;

      case 'citizen_report':
        targetRoute = AppRoutes.citizenReport;
        break;

      case 'education':
        targetRoute = AppRoutes.education;
        break;

      default:
        // Gunakan judul atau isi pesan hanya jika jenis
        // notifikasi belum dikenali.
        if (content.contains('tas siaga')) {
          targetRoute = AppRoutes.emergencyBag;
        } else if (content.contains('evakuasi')) {
          targetRoute = AppRoutes.evacuation;
        } else if (content.contains('cuaca')) {
          targetRoute = AppRoutes.weather;
        } else if (content.contains('ketinggian sungai')) {
          targetRoute = AppRoutes.riverHeight;
        } else if (content.contains('laporan warga') ||
            content.contains('lapor warga')) {
          targetRoute = AppRoutes.citizenReport;
        } else if (content.contains('edukasi')) {
          targetRoute = AppRoutes.education;
        } else if (content.contains('peringatan banjir') ||
            content.contains('status siaga')) {
          targetRoute = AppRoutes.alert;
        }
        break;
    }

    if (targetRoute == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Halaman tujuan untuk notifikasi ini belum ditentukan.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pushNamed(
      targetRoute,
      arguments: arguments,
    );
  }
  @override
  Widget build(BuildContext context) {
    return FeaturePageShell(
      title: 'Notifikasi',
      account: widget.account,
      locationService: widget.locationService,
      activeTab: 'Home',
      child: RefreshIndicator(
        onRefresh: () => _loadNotifications(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 22, 100),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Belum dibaca: $_unreadCount',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _notifications.isEmpty
                      ? null
                      : _deleteAll,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Hapus semua'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null && _notifications.isEmpty)
              _EmptyState(
                icon: Icons.cloud_off_outlined,
                message: 'Tidak dapat memuat notifikasi.',
                detail: _error!,
                onRetry: () => _loadNotifications(),
              )
            else if (_notifications.isEmpty)
              const _EmptyState(
                icon: Icons.notifications_none,
                message: 'Belum ada notifikasi',
                detail:
                    'Notifikasi baru akan muncul di sini '
                    'ketika tersedia.',
              )
            else ...[
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Pembaruan gagal: $_error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              for (final item in _notifications) ...[
                _NotificationCard(
                  item: item,
                  onTap: () => _openNotification(item),
                  onDelete: () => _deleteNotification(item),
                ),
                const SizedBox(height: 14),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final AppNotification item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isFlood = item.type == 'flood_alert';
    final isWeather = item.type == 'weather';

    final tint = isFlood || isWeather
        ? const Color(0xFFF3E3E1)
        : const Color(0xFFE6D6C2);

    final color = isFlood || isWeather
        ? const Color(0xFFC8282B)
        : const Color(0xFFBB6400);

    final tag = isFlood
        ? 'Peringatan banjir'
        : isWeather
            ? 'Peringatan cuaca'
            : 'Informasi';

    final age = item.createdAt == null
        ? ''
        : _formatDate(item.createdAt!);

    return Material(
      color: tint,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          const Text(
                            'BARU',
                            style: TextStyle(
                              color: Color(0xFFC8282B),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Hapus notifikasi',
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFF555555),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                item.title,
                style: TextStyle(
                  fontWeight: item.isRead
                      ? FontWeight.w600
                      : FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.message,
                style: const TextStyle(
                  color: Color(0xFF4D4D4D),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                age,
                style: const TextStyle(
                  color: Color(0xFF929292),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 36,
                child: OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Lihat detail'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();

    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${twoDigits(local.day)}/'
        '${twoDigits(local.month)}/'
        '${local.year} '
        '${twoDigits(local.hour)}:'
        '${twoDigits(local.minute)}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.detail,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final String detail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 42,
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Coba lagi'),
            ),
          ],
        ],
      ),
    );
  }
}