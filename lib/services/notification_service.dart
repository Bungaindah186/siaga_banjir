import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_client.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.readAt,
    this.floodAlertId,
  });

  final int id;
  final String type;
  final String title;
  final String message;
  final DateTime? createdAt;
  final DateTime? readAt;
  final int? floodAlertId;

  bool get isRead => readAt != null;

  factory AppNotification.fromJson(
    Map<String, dynamic> json,
  ) {
    return AppNotification(
      id: int.parse(json['id'].toString()),
      type: json['type']?.toString() ?? 'general',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      createdAt: DateTime.tryParse(
        json['created_at']?.toString() ?? '',
      ),
      readAt: json['read_at'] == null
          ? null
          : DateTime.tryParse(json['read_at'].toString()),
      floodAlertId: json['flood_alert_id'] == null
          ? null
          : int.tryParse(
              json['flood_alert_id'].toString(),
            ),
    );
  }
}

class NotificationListResult {
  const NotificationListResult({
    required this.notifications,
    required this.unreadCount,
  });

  final List<AppNotification> notifications;
  final int unreadCount;
}

class NotificationService {
  NotificationService({
    required this.apiClient,
    required this.token,
  });

  final ApiClient apiClient;
  final String token;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> _request(
    Future<http.Response> Function(Uri uri) send,
    String path,
  ) async {
    try {
      final response = await send(
        Uri.parse('${apiClient.baseUrl}/$path'),
      ).timeout(const Duration(seconds: 15));

      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(
              jsonDecode(response.body) as Map,
            );

      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        return decoded;
      }

      throw ApiException(
        decoded['message']?.toString() ??
            'Permintaan notifikasi gagal '
                '(HTTP ${response.statusCode}).',
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'Server terlalu lama merespons. Coba lagi.',
      );
    } on FormatException {
      throw const ApiException(
        'Respons server tidak dapat dibaca.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Tidak dapat terhubung ke server Laravel.',
      );
    }
  }

  Future<NotificationListResult> getNotifications() async {
    final response = await _request(
      (uri) => http.get(uri, headers: _headers),
      'notifications',
    );

    final rows = response['data'] as List? ?? [];

    final notifications = rows
        .map(
          (row) => AppNotification.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();

    return NotificationListResult(
      notifications: notifications,
      unreadCount: int.tryParse(
            response['unread_count'].toString(),
          ) ??
          0,
    );
  }

  Future<void> markAsRead(int id) async {
    await _request(
      (uri) => http.patch(uri, headers: _headers),
      'notifications/$id/read',
    );
  }

  Future<void> deleteNotification(int id) async {
    await _request(
      (uri) => http.delete(uri, headers: _headers),
      'notifications/$id',
    );
  }

  Future<void> deleteAllNotifications() async {
    await _request(
      (uri) => http.delete(uri, headers: _headers),
      'notifications',
    );
  }
}