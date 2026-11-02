import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../navigation/app_routes.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';

import 'dart:async';

import 'notification_bell.dart';

class FeaturePageShell extends StatelessWidget {
  const FeaturePageShell({
    super.key,
    required this.title,
    required this.account,
    required this.locationService,
    required this.activeTab,
    required this.child,
    this.showSos = true,
    this.showTopActions = true,
    this.showFamilyUnread = false,
  });

  final String title;
  final AuthenticatedUser account;
  final LocationService locationService;
  final String activeTab;
  final Widget child;
  final bool showSos;
  final bool showTopActions;
  final bool showFamilyUnread;

  AppRouteArguments get _arguments =>
      AppRouteArguments(account: account, locationService: locationService);

  void _open(BuildContext context, String route) {
    Navigator.of(context).pushNamed(route, arguments: _arguments);
  }

  Future<void> _showSosConfirmation(BuildContext context) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi SOS'),
        content: const Text('Apakah kamu ingin melanjutkan ke halaman SOS?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD5282B),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );

    if (confirmation == true && context.mounted) {
      Navigator.of(context).pushNamed(AppRoutes.sos, arguments: _arguments);
    }
  }

  void _selectTab(BuildContext context, String tab) {
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);
    if (tab == 'Home') return;
    final route = AppRoutes.sections[tab];
    if (route == null) return;
    navigator.pushNamed(route, arguments: _arguments);
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
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
            _FeatureHeader(
              title: title,
              account: account,
              showTopActions: showTopActions,
              onBack: () => Navigator.of(context).maybePop(),
              onCalendar: () => _open(context, AppRoutes.calendar),
              onNotifications: () => _open(context, AppRoutes.notifications),
              onProfile: () => _open(context, AppRoutes.profile),
              onMenu: () => _open(context, AppRoutes.menu),
              onSettings: () => _open(context, AppRoutes.settings),
            ),
            Expanded(child: child),
          ],
        ),
      ),
      floatingActionButton: showSos
          ? Transform.translate(
              offset: const Offset(-6, 0),
              child: SizedBox(
                width: 125,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => _showSosConfirmation(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD5282B),
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shape: const StadiumBorder(),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'SOS',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: AppMainNavigationBar(
        activeTab: activeTab,
        onSelected: (tab) => _selectTab(context, tab),
        token: account.token,
      ),
    ),
  );
}

class _FeatureHeader extends StatefulWidget {
  const _FeatureHeader({
    required this.title,
    required this.account,
    required this.showTopActions,
    required this.onBack,
    required this.onCalendar,
    required this.onNotifications,
    required this.onProfile,
    required this.onMenu,
    required this.onSettings,
  });

  final String title;
  final AuthenticatedUser account;
  final bool showTopActions;
  final VoidCallback onBack;
  final VoidCallback onCalendar;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;
  final VoidCallback onMenu;
  final VoidCallback onSettings;

  @override
  State<_FeatureHeader> createState() => _FeatureHeaderState();
}

class _FeatureHeaderState extends State<_FeatureHeader> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 124,
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        17,
        MediaQuery.paddingOf(context).top + 8,
        13,
        13,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0B2E3B),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Kembali',
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: Colors.white,
          ),
          Expanded(
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (widget.showTopActions) ...[
            IconButton(
              tooltip: 'Kalender',
              onPressed: widget.onCalendar,
              icon: const Icon(Icons.calendar_month_outlined),
              color: Colors.white,
            ),
            NotificationBell(
              account: widget.account,
              onPressed: widget.onNotifications,
              backgroundColor: const Color(0xFF0B2E3B),
              iconSize: 24,
              buttonSize: 48,
            ),
            PopupMenuButton<String>(
              tooltip: 'Menu lainnya',
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              color: Colors.white,
              onSelected: (value) {
                switch (value) {
                  case 'profil':
                    widget.onProfile();
                    break;
                  case 'menu':
                    widget.onMenu();
                    break;
                  case 'pengaturan':
                    widget.onSettings();
                    break;
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
                      Icon(Icons.menu_rounded, color: Color(0xFF0B2E3B)),
                      SizedBox(width: 10),
                      Text('Menu'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'pengaturan',
                  child: Row(
                    children: [
                      Icon(Icons.settings_outlined, color: Color(0xFF0B2E3B)),
                      SizedBox(width: 10),
                      Text('Pengaturan'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class AppMainNavigationBar extends StatefulWidget {
  const AppMainNavigationBar({
    super.key,
    required this.activeTab,
    required this.onSelected,
    required this.token,
  });

  final String activeTab;
  final ValueChanged<String> onSelected;
  final String token;

  @override
  State<AppMainNavigationBar> createState() => _AppMainNavigationBarState();
}

class _AppMainNavigationBarState extends State<AppMainNavigationBar> {
  final ApiClient _apiClient = ApiClient();

  int _unreadCount = 0;
  Timer? _unreadTimer;

  static const _items = <(String, IconData)>[
    ('Home', Icons.home_outlined),
    ('Evakuasi', Icons.location_on_outlined),
    ('Cuaca', Icons.cloud_outlined),
    ('Keluarga', Icons.people_outline),
    ('Kontak', Icons.call_outlined),
  ];

  @override
  void initState() {
    super.initState();

    _loadUnreadCount();

    _unreadTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      // Perbarui jumlah pesan hanya pada halaman yang sedang aktif.
      if (mounted) {
        _loadUnreadCount();
      }
    });
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _apiClient.fetchFamilyUnreadCount(
        token: widget.token,
      );

      if (!mounted) return;

      if (_unreadCount != count) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (_) {
      // Jika permintaan gagal, pertahankan jumlah sebelumnya.
    }
  }

  @override
  void dispose() {
    _unreadTimer?.cancel();
    _apiClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 8,
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: (99 - MediaQuery.paddingOf(context).bottom).clamp(68.0, 99.0),
        child: Row(
          children: [
            for (final (label, icon) in _items)
              Expanded(
                child: InkWell(
                  onTap: () => widget.onSelected(label),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.activeTab == label
                            ? const Color(0xFFD7EFE5)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                icon,
                                size: 32,
                                color: widget.activeTab == label
                                    ? Colors.green
                                    : Colors.black,
                              ),
                              if (label == 'Keluarga' && _unreadCount > 0)
                                Positioned(
                                  right: -2,
                                  top: -1,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            label,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.activeTab == label
                                  ? Colors.green
                                  : Colors.black,
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
  );
}
