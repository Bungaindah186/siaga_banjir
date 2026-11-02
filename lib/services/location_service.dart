import 'dart:async';

import 'package:geolocator/geolocator.dart';

enum LocationStatus {
  available,
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  failed,
}

class LocationResult {
  const LocationResult(this.status, {this.position, this.message});

  final LocationStatus status;
  final Position? position;
  final String? message;
}

class LocationService {
  Future<LocationResult> checkAndGetCurrentPosition() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult(LocationStatus.permissionDenied);
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(LocationStatus.permissionDeniedForever);
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return const LocationResult(LocationStatus.permissionDenied);
      }

      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult(LocationStatus.serviceDisabled);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LocationResult(LocationStatus.available, position: position);
    } on LocationServiceDisabledException {
      return const LocationResult(LocationStatus.serviceDisabled);
    } on PermissionDeniedException {
      final permission = await Geolocator.checkPermission();
      return LocationResult(
        permission == LocationPermission.deniedForever
            ? LocationStatus.permissionDeniedForever
            : LocationStatus.permissionDenied,
      );
    } on TimeoutException {
      return const LocationResult(
        LocationStatus.failed,
        message:
            'Lokasi perangkat tidak ditemukan dalam batas waktu. Coba lagi.',
      );
    } catch (_) {
      return const LocationResult(
        LocationStatus.failed,
        message: 'Lokasi perangkat gagal diperoleh. Coba lagi.',
      );
    }
  }

  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<LocationStatus> checkPermissionStatus() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return LocationStatus.available;
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationStatus.permissionDeniedForever;
    }
    return LocationStatus.permissionDenied;
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
