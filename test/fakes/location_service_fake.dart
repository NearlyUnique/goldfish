import 'package:geolocator/geolocator.dart';
import 'package:goldfish/core/location/location_service.dart';

/// Fake implementation of [LocationService] for testing.
///
/// Uses function fields so tests can control behavior per test.
class FakeLocationService implements LocationService {
  FakeLocationService({
    Future<bool> Function()? onRequestPermission,
    Future<bool> Function()? onHasPermission,
    Future<Position?> Function()? onGetCurrentLocation,
    Future<bool> Function()? onIsLocationServiceEnabled,
    Future<bool> Function()? onIsPermissionDeniedForever,
    Future<bool> Function()? onOpenAppSettings,
  })  : onRequestPermission =
            onRequestPermission ?? _defaultRequestPermission,
        onHasPermission = onHasPermission ?? _defaultHasPermission,
        onGetCurrentLocation =
            onGetCurrentLocation ?? _defaultGetCurrentLocation,
        onIsLocationServiceEnabled =
            onIsLocationServiceEnabled ?? _defaultIsLocationServiceEnabled,
        onIsPermissionDeniedForever =
            onIsPermissionDeniedForever ?? _defaultIsPermissionDeniedForever,
        onOpenAppSettings = onOpenAppSettings ?? _defaultOpenAppSettings;

  Future<bool> Function() onRequestPermission;
  Future<bool> Function() onHasPermission;
  Future<Position?> Function() onGetCurrentLocation;
  Future<bool> Function() onIsLocationServiceEnabled;
  Future<bool> Function() onIsPermissionDeniedForever;
  Future<bool> Function() onOpenAppSettings;

  @override
  Future<bool> requestPermission() => onRequestPermission();

  @override
  Future<bool> hasPermission() => onHasPermission();

  @override
  Future<Position?> getCurrentLocation() => onGetCurrentLocation();

  @override
  Future<bool> isLocationServiceEnabled() => onIsLocationServiceEnabled();

  @override
  Future<bool> isPermissionDeniedForever() => onIsPermissionDeniedForever();

  @override
  Future<bool> openAppSettings() => onOpenAppSettings();

  static Future<bool> _defaultRequestPermission() async => false;
  static Future<bool> _defaultHasPermission() async => false;
  static Future<Position?> _defaultGetCurrentLocation() async => null;
  static Future<bool> _defaultIsLocationServiceEnabled() async => false;
  static Future<bool> _defaultIsPermissionDeniedForever() async => false;
  static Future<bool> _defaultOpenAppSettings() async => true;
}


