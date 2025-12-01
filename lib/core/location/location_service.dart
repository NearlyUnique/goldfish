import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:goldfish/core/location/geolocator_wrapper.dart';
import 'package:goldfish/core/logging/app_logger.dart';

/// Abstract interface for location services.
///
/// Provides a testable abstraction over location operations, allowing
/// for easy mocking in tests and swapping implementations.
abstract class LocationService {
  /// Requests location permission from the user.
  ///
  /// Returns `true` if permission is granted, `false` if denied.
  /// Does not throw exceptions - returns false gracefully if permission
  /// is denied or unavailable.
  Future<bool> requestPermission();

  /// Checks if location permission has been granted.
  ///
  /// Returns `true` if permission is granted, `false` otherwise.
  Future<bool> hasPermission();

  /// Gets the current GPS location.
  ///
  /// Returns a [Position] with latitude and longitude if location is
  /// available. Returns `null` if:
  /// - Permission is denied
  /// - Location services are disabled
  /// - Location is unavailable
  /// - A timeout occurs
  ///
  /// Does not throw exceptions - returns null gracefully on any error.
  Future<Position?> getCurrentLocation();

  /// Checks if location services are enabled on the device.
  ///
  /// Returns `true` if location services are enabled, `false` otherwise.
  Future<bool> isLocationServiceEnabled();
}

/// Concrete implementation of [LocationService] using the geolocator package.
///
/// This implementation handles location permissions and GPS location capture
/// with graceful error handling. It does not throw exceptions for permission
/// denials or location unavailability - instead returns null or false.
class GeolocatorLocationService implements LocationService {
  /// Creates a new [GeolocatorLocationService].
  ///
  /// Optionally accepts [locationSettings] for custom location accuracy
  /// settings. If not provided, uses default settings with high accuracy.
  /// Optionally accepts [geolocatorWrapper] for dependency injection and testing.
  /// If not provided, uses [GeolocatorPackageWrapper] as the default.
  GeolocatorLocationService({
    LocationSettings? locationSettings,
    GeolocatorWrapper? geolocatorWrapper,
  }) : _locationSettings =
           locationSettings ??
           const LocationSettings(
             accuracy: LocationAccuracy.high,
             timeLimit: Duration(seconds: 10),
           ),
       _geolocatorWrapper =
           geolocatorWrapper ?? const GeolocatorPackageWrapper();

  final LocationSettings _locationSettings;
  final GeolocatorWrapper _geolocatorWrapper;

  @override
  Future<bool> requestPermission() async {
    try {
      // Check if location services are enabled first
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.info({
          'event': 'location_permission_request',
          'status': 'location_services_disabled',
        });
        return false;
      }

      // Check current permission status
      LocationPermission permission = await _geolocatorWrapper
          .checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        AppLogger.info({
          'event': 'location_permission_request',
          'status': 'already_granted',
        });
        return true;
      }

      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await _geolocatorWrapper.requestPermission();
        final granted =
            permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse;

        AppLogger.info({
          'event': 'location_permission_request',
          'status': granted ? 'granted' : 'denied',
        });

        return granted;
      }

      // Permission is denied forever
      if (permission == LocationPermission.deniedForever) {
        AppLogger.info({
          'event': 'location_permission_request',
          'status': 'denied_forever',
        });
        return false;
      }

      // Unknown permission status
      AppLogger.info({
        'event': 'location_permission_request',
        'status': 'unknown',
        'permission': permission.toString(),
      });
      return false;
    } catch (e) {
      AppLogger.error({
        'event': 'location_permission_request_error',
        'error': e.toString(),
      });
      // Don't throw - return false gracefully
      return false;
    }
  }

  @override
  Future<bool> hasPermission() async {
    try {
      final permission = await _geolocatorWrapper.checkPermission();
      final hasPermission =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      AppLogger.info({
        'event': 'location_permission_check',
        'has_permission': hasPermission,
      });

      return hasPermission;
    } catch (e) {
      AppLogger.error({
        'event': 'location_permission_check_error',
        'error': e.toString(),
      });
      // Don't throw - return false gracefully
      return false;
    }
  }

  @override
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.info({
          'event': 'location_get_current',
          'status': 'location_services_disabled',
        });
        return null;
      }

      // Check if permission is granted
      final hasPermission = await this.hasPermission();
      if (!hasPermission) {
        AppLogger.info({
          'event': 'location_get_current',
          'status': 'permission_denied',
        });
        return null;
      }

      // Get current position
      final position = await _geolocatorWrapper.getCurrentPosition(
        locationSettings: _locationSettings,
      );

      AppLogger.info({
        'event': 'location_get_current',
        'status': 'success',
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      });

      return position;
    } on LocationServiceDisabledException catch (e) {
      AppLogger.error({
        'event': 'location_get_current',
        'status': 'location_services_disabled',
        'error': e.toString(),
      });
      // Don't throw - return null gracefully
      return null;
    } on TimeoutException catch (e) {
      AppLogger.error({
        'event': 'location_get_current',
        'status': 'timeout',
        'error': e.toString(),
      });
      // Don't throw - return null gracefully
      return null;
    } catch (e) {
      AppLogger.error({
        'event': 'location_get_current',
        'status': 'error',
        'error': e.toString(),
      });
      // Don't throw - return null gracefully
      return null;
    }
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      final enabled = await _geolocatorWrapper.isLocationServiceEnabled();
      AppLogger.info({
        'event': 'location_service_enabled_check',
        'enabled': enabled,
      });
      return enabled;
    } catch (e) {
      AppLogger.error({
        'event': 'location_service_enabled_check_error',
        'error': e.toString(),
      });
      // Don't throw - return false gracefully
      return false;
    }
  }
}
