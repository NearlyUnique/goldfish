import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:goldfish/core/location/geolocator_wrapper.dart';

/// Fake implementation of [GeolocatorWrapper] for testing.
///
/// Provides function fields that tests can configure to control behavior.
class FakeGeolocatorWrapper implements GeolocatorWrapper {
  /// Creates a new [FakeGeolocatorWrapper].
  ///
  /// Optionally accepts function handlers for each method. If not provided,
  /// uses default implementations.
  FakeGeolocatorWrapper({
    Future<LocationPermission> Function()? onCheckPermission,
    Future<LocationPermission> Function()? onRequestPermission,
    Future<Position> Function({LocationSettings? locationSettings})?
        onGetCurrentPosition,
    Future<bool> Function()? onIsLocationServiceEnabled,
  })  : onCheckPermission = onCheckPermission ?? _defaultCheckPermission,
        onRequestPermission = onRequestPermission ?? _defaultRequestPermission,
        onGetCurrentPosition =
            onGetCurrentPosition ?? _defaultGetCurrentPosition,
        onIsLocationServiceEnabled =
            onIsLocationServiceEnabled ?? _defaultIsLocationServiceEnabled;

  /// Handler for [checkPermission].
  Future<LocationPermission> Function() onCheckPermission;

  /// Handler for [requestPermission].
  Future<LocationPermission> Function() onRequestPermission;

  /// Handler for [getCurrentPosition].
  Future<Position> Function({LocationSettings? locationSettings})
      onGetCurrentPosition;

  /// Handler for [isLocationServiceEnabled].
  Future<bool> Function() onIsLocationServiceEnabled;

  @override
  Future<LocationPermission> checkPermission() => onCheckPermission();

  @override
  Future<LocationPermission> requestPermission() => onRequestPermission();

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) =>
      onGetCurrentPosition(locationSettings: locationSettings);

  @override
  Future<bool> isLocationServiceEnabled() => onIsLocationServiceEnabled();

  // Default implementations
  static Future<LocationPermission> _defaultCheckPermission() async =>
      LocationPermission.denied;
  static Future<LocationPermission> _defaultRequestPermission() async =>
      LocationPermission.denied;
  static Future<Position> _defaultGetCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    throw UnimplementedError('getCurrentPosition not configured in test');
  }

  static Future<bool> _defaultIsLocationServiceEnabled() async => false;
}

