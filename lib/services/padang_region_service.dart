import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

class PadangRegion {
  const PadangRegion({
    required this.name,
    required this.district,
    required this.adm4,
  });

  final String name;
  final String district;
  final String adm4;
}

class PadangRegionService {
  static const String _assetPath = 'assets/geo/padang_kelurahan.geojson';

  List<Map<String, dynamic>>? _features;

  Future<void> _loadFeatures() async {
    if (_features != null) return;

    final content = await rootBundle.loadString(_assetPath);
    final geojson = jsonDecode(content) as Map<String, dynamic>;
    final rawFeatures = geojson['features'] as List<dynamic>;

    _features = rawFeatures.whereType<Map<String, dynamic>>().toList();
  }

  Future<PadangRegion?> findRegion(LatLng point) async {
    await _loadFeatures();

    for (final feature in _features!) {
      final properties = feature['properties'] as Map<String, dynamic>? ?? {};

      final name = properties['kel_desa']?.toString() ?? '';
      final district = properties['kecamatan']?.toString() ?? '';
      final adm4 = properties['kode_kd']?.toString() ?? '';

      if (name.isEmpty || adm4.isEmpty || !_isValidAdm4(adm4)) {
        continue;
      }

      final geometry = feature['geometry'] as Map<String, dynamic>?;

      if (geometry == null) continue;

      final coordinates = geometry['coordinates'];

      if (_containsPoint(coordinates, point.longitude, point.latitude)) {
        return PadangRegion(name: name, district: district, adm4: adm4);
      }
    }

    return null;
  }

  bool _isValidAdm4(String code) {
    return RegExp(r'^\d{2}\.\d{2}\.\d{2}\.\d{4}$').hasMatch(code);
  }

  bool _containsPoint(dynamic coordinates, double longitude, double latitude) {
    if (coordinates is! List) return false;

    // GeoJSON MultiPolygon memiliki struktur:
    // polygon -> ring -> [longitude, latitude].
    for (final polygon in coordinates) {
      if (polygon is! List || polygon.isEmpty) continue;

      final outerRing = polygon.first;

      if (_pointInRing(outerRing, longitude, latitude)) {
        // Periksa apakah titik berada di lubang poligon.
        var inHole = false;

        for (var i = 1; i < polygon.length; i++) {
          if (_pointInRing(polygon[i], longitude, latitude)) {
            inHole = true;
            break;
          }
        }

        if (!inHole) return true;
      }
    }

    return false;
  }

  bool _pointInRing(dynamic ring, double longitude, double latitude) {
    if (ring is! List || ring.length < 4) return false;

    var inside = false;
    var j = ring.length - 1;

    for (var i = 0; i < ring.length; i++) {
      final current = ring[i];
      final previous = ring[j];

      if (current is! List ||
          previous is! List ||
          current.length < 2 ||
          previous.length < 2) {
        j = i;
        continue;
      }

      final xi = (current[0] as num).toDouble();
      final yi = (current[1] as num).toDouble();
      final xj = (previous[0] as num).toDouble();
      final yj = (previous[1] as num).toDouble();

      final crosses = (yi > latitude) != (yj > latitude);

      if (crosses) {
        final intersectionX = (xj - xi) * (latitude - yi) / (yj - yi) + xi;

        if (longitude < intersectionX) {
          inside = !inside;
        }
      }

      j = i;
    }

    return inside;
  }
}
