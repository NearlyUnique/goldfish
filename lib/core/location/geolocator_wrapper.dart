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

  /// Checks if location services are enabled on the device.
  Future<bool> isLocationServiceEnabled();
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
  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }
}
