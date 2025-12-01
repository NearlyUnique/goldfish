import 'package:geolocator/geolocator.dart';
import 'package:goldfish/core/location/location_service.dart';

/// Fake implementation of [LocationService] for testing.
///
/// Provides function fields that tests can configure to control behavior.
/// Default implementations return safe defaults (false, null) so tests
/// only need to configure the behavior they care about.
class FakeLocationService implements LocationService {
  /// Creates a new [FakeLocationService].
  ///
  /// Optionally accepts function handlers for each method. If not provided,
  /// uses default implementations that return safe defaults.
  FakeLocationService({
    Future<bool> Function()? onRequestPermission,
    Future<bool> Function()? onHasPermission,
    Future<Position?> Function()? onGetCurrentLocation,
    Future<bool> Function()? onIsLocationServiceEnabled,
  }) : onRequestPermission = onRequestPermission ?? _defaultRequestPermission,
       onHasPermission = onHasPermission ?? _defaultHasPermission,
       onGetCurrentLocation =
           onGetCurrentLocation ?? _defaultGetCurrentLocation,
       onIsLocationServiceEnabled =
           onIsLocationServiceEnabled ?? _defaultIsLocationServiceEnabled;

  /// Handler for [requestPermission].
  Future<bool> Function() onRequestPermission;

  /// Handler for [hasPermission].
  Future<bool> Function() onHasPermission;

  /// Handler for [getCurrentLocation].
  Future<Position?> Function() onGetCurrentLocation;

  /// Handler for [isLocationServiceEnabled].
  Future<bool> Function() onIsLocationServiceEnabled;

  @override
  Future<bool> requestPermission() => onRequestPermission();

  @override
  Future<bool> hasPermission() => onHasPermission();

  @override
  Future<Position?> getCurrentLocation() => onGetCurrentLocation();

  @override
  Future<bool> isLocationServiceEnabled() => onIsLocationServiceEnabled();

  // Default implementations
  static Future<bool> _defaultRequestPermission() async => false;
  static Future<bool> _defaultHasPermission() async => false;
  static Future<Position?> _defaultGetCurrentLocation() async => null;
  static Future<bool> _defaultIsLocationServiceEnabled() async => false;
}
