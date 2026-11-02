import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../widgets/feature_page_shell.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({
    super.key,
    required this.account,
    required this.locationService,
    this.onLogout,
  });

  final AuthenticatedUser account;
  final LocationService locationService;
  final VoidCallback? onLogout;

  void _open(
    BuildContext context,
    String route, {
    String? title,
    String? detail,
  }) {
    Navigator.of(context).pushNamed(
      route,
      arguments: AppRouteArguments(
        account: account,
        locationService: locationService,
        onLogout: onLogout,
        title: title,
        detail: detail,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FeaturePageShell(
    title: 'Menu',
    account: account,
    locationService: locationService,
    activeTab: 'Home',
    child: ListView(
      padding: const EdgeInsets.fromLTRB(24, 19, 24, 100),
      children: [
        _MenuItem(
          icon: Icons.menu_book_outlined,
          title: 'Edukasi',
          onTap: () => _open(context, AppRoutes.education),
        ),
        _MenuItem(
          icon: Icons.water_drop_outlined,
          title: 'Cek Ketinggian air',
          onTap: () => _open(context, AppRoutes.riverHeight),
        ),
        _MenuItem(
          icon: Icons.person_add_alt_1_outlined,
          title: 'Lapor Warga',
          onTap: () => _open(context, AppRoutes.citizenReport),
        ),
        _MenuItem(
          icon: Icons.history_rounded,
          title: 'Riwayat Bencana',
          onTap: () => _open(context, AppRoutes.disasterHistory),
        ),
        _MenuItem(
          icon: Icons.settings_outlined,
          title: 'Pengaturan',
          onTap: () => _open(context, AppRoutes.settings),
        ),
        const SizedBox(height: 5),
        _MenuItem(
          icon: Icons.logout_rounded,
          title: 'Logout',
          dark: true,
          onTap: () {
            if (onLogout != null) {
              onLogout!();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fungsi logout belum tersedia.'),
                ),
              );
            }
          },
        ),        
      ],
    ),
  );
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.dark = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: dark ? const Color(0xFF0B2E3B) : Colors.white,
      borderRadius: BorderRadius.circular(23),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(23),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: dark ? Colors.white : const Color(0xFF536269)),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: dark ? Colors.white : Colors.black,
                  fontSize: 17,
                  fontWeight: dark ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
