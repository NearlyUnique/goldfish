import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:goldfish/core/location/location_service.dart';
import '../../fakes/geolocator_wrapper_fake.dart';
import 'test_helpers.dart';

void main() {
  group('GeolocatorLocationService', () {
    test('implements LocationService interface', () {
      // Arrange & Act
      final service = GeolocatorLocationService();

      // Assert
      expect(service, isA<LocationService>());
    });

    test('accepts custom location settings', () {
      // Arrange
      const customSettings = LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 5),
      );

      // Act
      final service = GeolocatorLocationService(
        locationSettings: customSettings,
      );

      // Assert
      expect(service, isA<LocationService>());
    });

    group('requestPermission', () {
      test('returns false when location services disabled', () async {
        // Arrange
        final wrapper = FakeGeolocatorWrapper(
          onIsLocationServiceEnabled: () async => false,
        );
        final service = createLocationServiceWithWrapper(wrapper);

        // Act
        final result = await service.requestPermission();

        // Assert
        expect(result, isFalse);
      });

      test('returns true when permission already granted (always)', () async {
        // Arrange
        final wrapper = FakeGeolocatorWrapper(
          onIsLocationServiceEnabled: () async => true,
          onCheckPermission: () async => LocationPermission.always,
        );
        final service = createLocationServiceWithWrapper(wrapper);

        // Act
        final result = await service.requestPermission();

        // Assert
        expect(result, isTrue);
      });

      test(
        'returns true when permission already granted (whileInUse)',
        () async {
          // Arrange
          final wrapper = FakeGeolocatorWrapper(
            onIsLocationServiceEnabled: () async => true,
            onCheckPermission: () async => LocationPermission.whileInUse,
          );
          final service = GeolocatorLocationService(geolocatorWrapper: wrapper);

          // Act
          final result = await service.requestPermission();

          // Assert
          expect(result, isTrue);
        },
      );

      test('requests permission when denied and returns true', () async {
        // Arrange
        final wrapper = FakeGeolocatorWrapper(
          onIsLocationServiceEnabled: () async => true,
          onCheckPermission: () async => LocationPermission.denied,
          onRequestPermission: () async => LocationPermission.whileInUse,
        );
        final service = createLocationServiceWithWrapper(wrapper);

        // Act
        final result = await service.requestPermission();

        // Assert
        expect(result, isTrue);
      });

      test('requests permission when denied and returns false', () async {
        // Arrange
        final wrapper = FakeGeolocatorWrapper(
          onIsLocationServiceEnabled: () async => true,
          onCheckPermission: () async => LocationPermission.denied,
          onRequestPermission: () async => LocationPermission.denied,
        );
        final service = createLocationServiceWithWrapper(wrapper);

        // Act
        final result = await service.requestPermission();

        // Assert
        expect(result, isFalse);
      });

      test('returns false when permission denied forever', () async {
        // Arrange
        final wrapper = FakeGeolocatorWrapper(
          onIsLocationServiceEnabled: () async => true,
          onCheckPermission: () async => LocationPermission.deniedForever,
        );
        final service = createLocationServiceWithWrapper(wrapper);

        // Act
        final result = await service.requestPermission();

        // Assert
        expect(result, isFalse);
      });

      test('returns false on exception', () async {
        // Arrange
        final wrapper = FakeGeolocatorWrapper(
          onIsLocationServiceEnabled: () async => true,
          onCheckPermission: () async {
            throw Exception('Permission check failed');
          },
        );
        final service = createLocationServiceWithWrapper(wrapper);

        // Act
        final result = await service.requestPermission();

        // Assert
        expect(result, isFalse);
      });
    });

    group('hasPermission', () {
      test('returns true when permission granted (always)', () async {
        // Arrange
        final wrapper = FakeGeolocatorWrapper(
          onCheckPermission: () async => LocationPermission.always,
        );
        final service = createLocationServiceWithWrapper(wrapper);

        // Act
        final result = await service.hasPermission();

        // Assert
        expect(result, isTrue);
      });

      test('returns true when permission granted (whileInUse)', () async {
        // Arrange
        final wrapper = FakeGeolocatorWrapper(
          onCheckPermission: () async => LocationPermission.whileInUse,
        );
        final service = createLocationServiceWithWrapper(wrapper);

        // Act
        final result = await service.hasPermission();

        // Assert
        expect(result, isTrue);
      });

      test('returns false when permission denied', () async {
        // Arrange
        final wrapper = FakeGeolocatorWrapper(
          onCheckPermission: () async => LocationPermission.denied,
        );
        final service = createLocationServiceWithWrapper(wrapper);

        // Act
        final result = await service.hasPermission();

        // Assert
        expect(result, isFalse);
      });

      test('returns false on exception', () async {
        // Arrange
        final wrapper = FakeGeolocatorWrapper(
          onCheckPermission: () async {
            throw Exception('Permission check failed');
          },
        );
        final service = createLocationServiceWithWrapper(wrapper);

        // Act
        final result = await service.hasPermission();

        // Assert
        expect(result, isFalse);
      });
    });

    group('getCurrentLocation', () {
      test('returns null when location services disabled', () async {
        // Arrange
        final wrapper = FakeGeolocatorWrapper(
          onIsLocationServiceEnabled: () async => false,
        );
        final service = createLocationServiceWithWrapper(wrapper);

        // Act
        final result = await service.getCurrentLocation();

        // Assert
        expect(result, isNull);
      });

      test('returns null when permission denied', () async {
        // Arrange
        final wrapper = FakeGeolocatorWrapper(
          onIsLocationServiceEnabled: () async => true,
          onCheckPermission: () async => LocationPermission.denied,
        );
        final service = createLocationServiceWithWrapper(wrapper);

        // Act
        final result = await service.getCurrentLocation();

        // Assert
        expect(result, isNull);
      });

      test('returns null when hasPermission throws exception', () async {
        // Arrange - test error handling when hasPermission check fails
        final wrapper = FakeGeolocatorWrapper(
          onIsLocationServiceEnabled: () async => true,
          onCheckPermission: () async {
            throw Exception('Permission check failed');
          },
        );
        final service = createLocationServiceWithWrapper(wrapper);

        // Act
        final result = await service.getCurrentLocation();

        // Assert - should return null gracefully when hasPermission throws
        expect(result, isNull);
      });

      test('returns position when all conditions met', () async {
        // Arrange
        final expectedPosition = createTestPosition(lat: 45.0, lon: -90.0);

        final wrapper = FakeGeolocatorWrapper(
          onIsLocationServiceEnabled: () async => true,
          onCheckPermission: () async => LocationPermission.whileInUse,
          onGetCurrentPosition: ({LocationSettings? locationSettings}) async =>
              expectedPosition,
        );
        final service = createLocationServiceWithWrapper(wrapper);

        // Act
        final result = await service.getCurrentLocation();

        // Assert
        expect(result, isNotNull);
        final position = result!;
        expect(position.latitude, equals(45.0));
        expect(position.longitude, equals(-90.0));
      });

      test('returns null on LocationServiceDisabledException', () async {
        // Arrange
        final wrapper = FakeGeolocatorWrapper(
          onIsLocationServiceEnabled: () async => true,
          onCheckPermission: () async => LocationPermission.whileInUse,
          onGetCurrentPosition: ({LocationSettings? locationSettings}) async {
            throw LocationServiceDisabledException();
          },
        );
        final service = createLocationServiceWithWrapper(wrapper);

        // Act
        final result = await service.getCurrentLocation();

        // Assert
        expect(result, isNull);
      });

      test('returns null on TimeoutException', () async {
        // Arrange
        final wrapper = FakeGeolocatorWrapper(
          onIsLocationServiceEnabled: () async => true,
          onCheckPermission: () async => LocationPermission.whileInUse,
          onGetCurrentPosition: ({LocationSettings? locationSettings}) async {
            throw TimeoutException('Location timeout');
          },
        );
        final service = createLocationServiceWithWrapper(wrapper);

        // Act
        final result = await service.getCurrentLocation();

        // Assert
        expect(result, isNull);
      });

      test('returns null on generic exception', () async {
        // Arrange
        final wrapper = FakeGeolocatorWrapper(
          onIsLocationServiceEnabled: () async => true,
          onCheckPermission: () async => LocationPermission.whileInUse,
          onGetCurrentPosition: ({LocationSettings? locationSettings}) async {
            throw Exception('Location unavailable');
          },
        );
        final service = createLocationServiceWithWrapper(wrapper);

        // Act
        final result = await service.getCurrentLocation();

        // Assert
        expect(result, isNull);
      });
    });

    group('isLocationServiceEnabled', () {
      test('returns true when services enabled', () async {
        // Arrange
        final wrapper = FakeGeolocatorWrapper(
          onIsLocationServiceEnabled: () async => true,
        );
        final service = createLocationServiceWithWrapper(wrapper);

        // Act
        final result = await service.isLocationServiceEnabled();

        // Assert
        expect(result, isTrue);
      });

      test('returns false when services disabled', () async {
        // Arrange
        final wrapper = FakeGeolocatorWrapper(
          onIsLocationServiceEnabled: () async => false,
        );
        final service = createLocationServiceWithWrapper(wrapper);

        // Act
        final result = await service.isLocationServiceEnabled();

        // Assert
        expect(result, isFalse);
      });

      test('returns false on exception', () async {
        // Arrange
        final wrapper = FakeGeolocatorWrapper(
          onIsLocationServiceEnabled: () async {
            throw Exception('Service check failed');
          },
        );
        final service = createLocationServiceWithWrapper(wrapper);

        // Act
        final result = await service.isLocationServiceEnabled();

        // Assert
        expect(result, isFalse);
      });
    });
  });
}
