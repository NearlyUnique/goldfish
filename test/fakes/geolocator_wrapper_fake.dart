import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:goldfish/core/location/geolocator_wrapper.dart';

/// Fake implementation of [GeolocatorWrapper] for testing.
class FakeGeolocatorWrapper implements GeolocatorWrapper {
  FakeGeolocatorWrapper({
    Future<LocationPermission> Function()? onCheckPermission,
    Future<LocationPermission> Function()? onRequestPermission,
    Future<Position> Function({LocationSettings? locationSettings})?
        onGetCurrentPosition,
    Stream<Position> Function({LocationSettings? locationSettings})?
        onGetPositionStream,
    Future<bool> Function()? onIsLocationServiceEnabled,
    Future<bool> Function()? onOpenAppSettings,
  })  : onCheckPermission = onCheckPermission ?? _defaultCheckPermission,
        onRequestPermission = onRequestPermission ?? _defaultRequestPermission,
        onGetCurrentPosition =
            onGetCurrentPosition ?? _defaultGetCurrentPosition,
        onGetPositionStream =
            onGetPositionStream ?? _defaultGetPositionStream,
        onIsLocationServiceEnabled =
            onIsLocationServiceEnabled ?? _defaultIsLocationServiceEnabled,
        onOpenAppSettings = onOpenAppSettings ?? _defaultOpenAppSettings;

  Future<LocationPermission> Function() onCheckPermission;
  Future<LocationPermission> Function() onRequestPermission;
  Future<Position> Function({LocationSettings? locationSettings})
      onGetCurrentPosition;
  Stream<Position> Function({LocationSettings? locationSettings})
      onGetPositionStream;
  Future<bool> Function() onIsLocationServiceEnabled;
  Future<bool> Function() onOpenAppSettings;

  @override
  Future<LocationPermission> checkPermission() => onCheckPermission();

  @override
  Future<LocationPermission> requestPermission() => onRequestPermission();

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) =>
      onGetCurrentPosition(locationSettings: locationSettings);

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      onGetPositionStream(locationSettings: locationSettings);

  @override
  Future<bool> isLocationServiceEnabled() => onIsLocationServiceEnabled();

  @override
  Future<bool> openAppSettings() => onOpenAppSettings();

  static Future<LocationPermission> _defaultCheckPermission() async =>
      LocationPermission.denied;

  static Future<LocationPermission> _defaultRequestPermission() async =>
      LocationPermission.denied;

  static Future<Position> _defaultGetCurrentPosition({
    LocationSettings? locationSettings,
  }) async =>
      Position(
        latitude: 0,
        longitude: 0,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        headingAccuracy: 0,
        altitudeAccuracy: 0,
      );

  static Stream<Position> _defaultGetPositionStream({
    LocationSettings? locationSettings,
  }) =>
      const Stream<Position>.empty();

  static Future<bool> _defaultIsLocationServiceEnabled() async => false;

  static Future<bool> _defaultOpenAppSettings() async => true;
}


