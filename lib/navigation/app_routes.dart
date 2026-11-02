import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/location_service.dart';
import '../services/flood_alert_service.dart';

class AppRoutes {
  static const calendar = '/calendar';
  static const notifications = '/notifications';
  static const alert = '/alert';
  static const weather = '/weather';
  static const riverHeight = '/river-height';
  static const map = '/map';
  static const evacuation = '/evacuation';
  static const family = '/family';
  static const contacts = '/contacts';
  static const menu = '/menu';
  static const info = '/info';
  static const profile = '/profile';
  static const education = '/education';
  static const emergencyBag = '/emergency-bag';
  static const citizenReport = '/citizen-report';
  static const reportHistory = '/report-history';
  static const disasterHistory = '/disaster-history';
  static const settings = '/settings';
  static const homeLocation = '/home-location';
  static const familyAddPhone = '/family/add-phone';
  static const familyInviteCode = '/family/invite-code';
  static const familyJoinCode = '/family/join-code';
  static const sos = '/sos';
  static const sosComplete = '/sos/complete';

  static const sections = <String, String>{
    'Home': '/',
    'Evakuasi': evacuation,
    'Cuaca': weather,
    'Keluarga': family,
    'Kontak': contacts,
    'Edukasi': education,
  };

  static String forTitle(String title) => switch (title) {
    'Kalender' => calendar,
    'Notifikasi' => notifications,
    'Peringatan banjir' ||
    'Status Siaga' ||
    'Tunggul Hitam' ||
    'Air Tawar' => alert,
    'Cuaca' => weather,
    'Ketinggian Sungai' => riverHeight,
    'Peta' => map,
    'Evakuasi' => evacuation,
    'Keluarga' => family,
    'Kontak' => contacts,
    'Menu' => menu,
    'Profil' => profile,
    'Edukasi' => education,
    'Pengaturan' => settings,
    'Lapor Warga' => citizenReport,
    'Riwayat Laporan' => reportHistory,
    'Riwayat Bencana' => disasterHistory,
    _ => info,
  };
}

class AppRouteArguments {
  const AppRouteArguments({
    required this.account,
    required this.locationService,
    this.apiClient,
    this.onLogout,
    this.title,
    this.detail,
    this.locationName,
    this.status,
    this.selectedAlert,
    this.inviteCode,
  });

  final AuthenticatedUser account;
  final LocationService locationService;
  final ApiClient? apiClient;
  final VoidCallback? onLogout;
  final String? title;
  final String? detail;
  final String? locationName;
  final String? status;
  final FloodAlert? selectedAlert;
  final String? inviteCode;
}
