import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// ==========================================
// MODEL DATA BANJIR
// ==========================================

class FloodAlert {
  const FloodAlert({
    required this.id,
    required this.regionName,
    required this.status,
    required this.title,
    required this.description,
    required this.waterLevelCm,
    required this.riseRateCmPerHour,
    required this.position,
  });

  final int id;
  final String regionName;
  final String status;
  final String title;
  final String description;
  final double? waterLevelCm;
  final double? riseRateCmPerHour;
  final LatLng? position;

  factory FloodAlert.fromJson(Map<String, dynamic> json) {
    final latitude = json['latitude'];
    final longitude = json['longitude'];

    LatLng? position;

    if (latitude != null && longitude != null) {
      final lat = double.tryParse(latitude.toString());
      final lng = double.tryParse(longitude.toString());

      if (lat != null &&
          lng != null &&
          lat >= -90 &&
          lat <= 90 &&
          lng >= -180 &&
          lng <= 180) {
        position = LatLng(lat, lng);
      }
    }

    return FloodAlert(
      id: int.parse(json['id'].toString()),
      regionName: json['region_name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      waterLevelCm: double.tryParse(json['water_level_cm']?.toString() ?? ''),
      riseRateCmPerHour: double.tryParse(
        json['rise_rate_cm_per_hour']?.toString() ?? '',
      ),
      position: position,
    );
  }
}

// ==========================================
// SERVICE UNTUK MENGAMBIL DATA DARI API
// ==========================================

class FloodAlertService {
  FloodAlertService({this.baseUrl = 'http://10.77.170.215:8000/api'});

  final String baseUrl;

  // Mengambil data status banjir
  Future<List<FloodAlert>> fetchAlerts() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/flood-alerts'),
          headers: {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengambil data banjir. HTTP ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic> || decoded['data'] is! List) {
      throw const FormatException('Format respons API banjir tidak sesuai.');
    }

    return (decoded['data'] as List)
        .whereType<Map<String, dynamic>>()
        .map(FloodAlert.fromJson)
        .toList();
  }

  // Mengambil riwayat pengukuran ketinggian air
  Future<List<RiverReading>> fetchReadings({
    required String token,
    required int floodAlertId,
    int hours = 6,
  }) async {
    final uri = Uri.parse('$baseUrl/river-readings').replace(
      queryParameters: {
        'flood_alert_id': floodAlertId.toString(),
        'hours': hours.toString(),
      },
    );

    final response = await http
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengambil riwayat pengukuran. HTTP ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic> || decoded['data'] is! List) {
      throw const FormatException(
        'Format respons riwayat pengukuran tidak sesuai.',
      );
    }

    return (decoded['data'] as List)
        .whereType<Map<String, dynamic>>()
        .map(RiverReading.fromJson)
        .toList();
  }
}

// ==========================================
// MODEL DATA RIWAYAT KETINGGIAN SUNGAI
// ==========================================

class RiverReading {
  const RiverReading({
    required this.id,
    required this.floodAlertId,
    required this.waterLevelCm,
    required this.measuredAt,
    this.riseRateCmPerHour,
  });

  final int id;
  final int floodAlertId;
  final double waterLevelCm;
  final double? riseRateCmPerHour;
  final DateTime measuredAt;

  factory RiverReading.fromJson(Map<String, dynamic> json) {
    return RiverReading(
      id: int.parse(json['id'].toString()),
      floodAlertId: int.parse(json['flood_alert_id'].toString()),
      waterLevelCm: double.parse(json['water_level_cm'].toString()),
      riseRateCmPerHour: double.tryParse(
        json['rise_rate_cm_per_hour']?.toString() ?? '',
      ),
      measuredAt: DateTime.parse(json['measured_at'].toString()),
    );
  }
}
