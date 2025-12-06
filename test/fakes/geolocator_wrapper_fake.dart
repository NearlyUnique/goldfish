import 'package:geolocator/geolocator.dart';
import 'package:goldfish/core/location/geolocator_wrapper.dart';

/// Fake implementation of [GeolocatorWrapper] for testing.
class FakeGeolocatorWrapper implements GeolocatorWrapper {
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

  Future<LocationPermission> Function() onCheckPermission;
  Future<LocationPermission> Function() onRequestPermission;
  Future<Position> Function({LocationSettings? locationSettings})
      onGetCurrentPosition;
  Future<bool> Function() onIsLocationServiceEnabled;

  @override
  Future<LocationPermission> checkPermission() => onCheckPermission();

  @override
  Future<LocationPermission> requestPermission() => onRequestPermission();

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) =>
      onGetCurrentPosition(locationSettings: locationSettings);

  @override
  Future<bool> isLocationServiceEnabled() => onIsLocationServiceEnabled();

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

  static Future<bool> _defaultIsLocationServiceEnabled() async => false;
}


