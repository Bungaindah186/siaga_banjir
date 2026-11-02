import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<String?> initialize() async {
    // Fokus integrasi saat ini adalah Android.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      debugPrint('FCM Android belum dijalankan pada platform ini.');
      return null;
    }

    // Meminta izin notifikasi.
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('Izin notifikasi: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Izin notifikasi ditolak oleh pengguna.');
      return null;
    }

    // Menerima pesan ketika aplikasi sedang terbuka.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Judul notifikasi: ${message.notification?.title}');
      debugPrint('Isi notifikasi: ${message.notification?.body}');
    });

    // Menerima interaksi ketika notifikasi ditekan.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notifikasi dibuka: ${message.messageId}');
    });
    final installationIdFuture = _messaging.onRegistered.first;

    await _messaging.register();

    final installationId = await installationIdFuture;

    debugPrint('Firebase Installation ID: $installationId');

    return installationId;
  }
}
