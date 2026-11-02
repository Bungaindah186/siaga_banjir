import 'package:flutter/material.dart';

import '../pages/alert_detail_screen.dart';
import '../pages/calendar_screen.dart';
import '../pages/contacts_screen.dart';
import '../pages/evacuation_screen.dart';
import '../pages/family_screen.dart';
import '../pages/map_screen.dart';
import '../pages/home_location_picker_screen.dart';
import '../pages/menu_screen.dart';
import '../pages/profile_screen.dart';
import '../pages/prototype_screens.dart';
import '../pages/notifications_screen.dart';
import '../pages/river_height_screen.dart';
import '../pages/simple_info_screen.dart';
import '../pages/weather_screen.dart';
import 'app_routes.dart';
import '../services/api_client.dart';

class AppRouteFactory {
  static Route<dynamic> generate(
    RouteSettings settings, {
    VoidCallback? onLogout,
  }) {
    final arguments = settings.arguments;
    debugPrint('ROUTE DIBUKA: ${settings.name}');
    if (arguments is! AppRouteArguments) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const Scaffold(
          body: Center(child: Text('Halaman tidak dapat dibuka.')),
        ),
      );
    }

    final account = arguments.account;
    final locationService = arguments.locationService;
    final Widget page = switch (settings.name) {
      AppRoutes.calendar => CalendarScreen(
        account: account,
        locationService: locationService,
      ),
      AppRoutes.notifications => NotificationsScreen(
        account: account,
        locationService: locationService,
      ),
      AppRoutes.alert => AlertDetailScreen(
        account: account,
        locationService: locationService,
        locationName: arguments.locationName,
        status: arguments.status,
        selectedAlert: arguments.selectedAlert,
      ),
      AppRoutes.weather => WeatherScreen(
        account: account,
        locationService: locationService,
      ),
      AppRoutes.riverHeight => RiverHeightScreen(
        account: account,
        locationService: locationService,
      ),
      AppRoutes.map => MapScreen(
        account: account,
        locationService: locationService,
      ),
      AppRoutes.evacuation => EvacuationScreen(
        account: account,
        locationService: locationService,
      ),
      AppRoutes.family => FamilyScreen(
        account: account,
        locationService: locationService,
      ),
      AppRoutes.contacts => ContactsScreen(
        account: account,
        locationService: locationService,
      ),
      AppRoutes.menu => MenuScreen(
        account: account,
        locationService: locationService,
        onLogout: onLogout ?? arguments.onLogout,
      ),
      AppRoutes.profile => ProfileScreen(
        account: account,
        locationService: locationService,
        apiClient: arguments.apiClient ?? ApiClient(),
      ),
      AppRoutes.settings => SettingsScreen(
        account: account,
        locationService: locationService,
      ),
      AppRoutes.education => EducationScreen(
        account: account,
        locationService: locationService,
      ),
      AppRoutes.emergencyBag => EmergencyBagScreen(
        account: account,
        locationService: locationService,
      ),
      AppRoutes.citizenReport => CitizenReportScreen(
        account: account,
        locationService: locationService,
      ),
      AppRoutes.reportHistory => ReportHistoryScreen(
        account: account,
        locationService: locationService,
      ),
      AppRoutes.disasterHistory => DisasterHistoryScreen(
        account: account,
        locationService: locationService,
      ),
      AppRoutes.homeLocation => HomeLocationPickerScreen(
        account: account,
        locationService: locationService,
        apiClient: arguments.apiClient ?? ApiClient(),
      ),
      AppRoutes.familyAddPhone => FamilyActionScreen(
        account: account,
        locationService: locationService,
        mode: 'phone',
      ),
      AppRoutes.familyInviteCode => FamilyActionScreen(
        account: account,
        locationService: locationService,
        mode: 'code',
        inviteCode: arguments.inviteCode,
      ),
      AppRoutes.familyJoinCode => FamilyActionScreen(
        account: account,
        locationService: locationService,
        mode: 'join',
      ),
      AppRoutes.sos => SosScreen(
        account: account,
        locationService: locationService,
      ),
      AppRoutes.sosComplete => SosCompleteScreen(
        account: account,
        locationService: locationService,
        emergencyType: arguments.title ?? 'Tidak diketahui',
        notifyFamily: arguments.detail == 'true',
      ),
      AppRoutes.info => SimpleInfoScreen(
        title: arguments.title ?? 'Informasi',
        detail: arguments.detail ?? 'Informasi ini belum tersedia.',
        account: account,
        locationService: locationService,
      ),
      _ => const Scaffold(
        body: Center(child: Text('Halaman tidak ditemukan.')),
      ),
    };
    return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
  }
}
