import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Abstract wrapper around geolocator static methods for testability.
///
/// Provides a testable abstraction over geolocator operations, allowing
/// for easy mocking in tests.
abstract class GeolocatorWrapper {
  /// Checks the current location permission status.
  Future<LocationPermission> checkPermission();

  /// Requests location permission from the user.
  Future<LocationPermission> requestPermission();

  /// Gets the current position with the given settings.
  Future<Position> getCurrentPosition({LocationSettings? locationSettings});

  /// Gets a stream of position updates with the given settings.
  ///
  /// The stream will emit position updates when the device moves by at least
  /// the distance specified in [locationSettings.distanceFilter], or when
  /// other location changes occur based on the settings.
  Stream<Position> getPositionStream({LocationSettings? locationSettings});

  /// Checks if location services are enabled on the device.
  Future<bool> isLocationServiceEnabled();

  /// Opens the app settings page where the user can grant location permission.
  ///
  /// Returns `true` if the settings page was opened successfully, `false` otherwise.
  Future<bool> openAppSettings();
}

/// Concrete implementation of [GeolocatorWrapper] using the geolocator package.
class GeolocatorPackageWrapper implements GeolocatorWrapper {
  /// Creates a new [GeolocatorPackageWrapper].
  const GeolocatorPackageWrapper();

  @override
  Future<LocationPermission> checkPermission() {
    return Geolocator.checkPermission();
  }

  @override
  Future<LocationPermission> requestPermission() {
    return Geolocator.requestPermission();
  }

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) {
    return Geolocator.getCurrentPosition(locationSettings: locationSettings);
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  @override
  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }
}
