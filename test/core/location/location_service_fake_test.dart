import 'package:flutter_test/flutter_test.dart';
import '../../fakes/location_service_fake.dart';
import 'test_helpers.dart';

/// Tests for [FakeLocationService] to verify the fake implementation
/// works correctly for use in other tests.
void main() {
  group('FakeLocationService', () {
    test('returns false for requestPermission by default', () async {
      // Arrange
      final service = FakeLocationService();

      // Act
      final result = await service.requestPermission();

      // Assert
      expect(result, isFalse);
    });

    test('returns configured value for requestPermission', () async {
      // Arrange
      final service = FakeLocationService(
        onRequestPermission: () async => true,
      );

      // Act
      final result = await service.requestPermission();

      // Assert
      expect(result, isTrue);
    });

    test('returns false for hasPermission by default', () async {
      // Arrange
      final service = FakeLocationService();

      // Act
      final result = await service.hasPermission();

      // Assert
      expect(result, isFalse);
    });

    test('returns configured value for hasPermission', () async {
      // Arrange
      final service = FakeLocationService(onHasPermission: () async => true);

      // Act
      final result = await service.hasPermission();

      // Assert
      expect(result, isTrue);
    });

    test('returns null for getCurrentLocation by default', () async {
      // Arrange
      final service = FakeLocationService();

      // Act
      final result = await service.getCurrentLocation();

      // Assert
      expect(result, isNull);
    });

    test('returns configured position for getCurrentLocation', () async {
      // Arrange
      final expectedPosition = createTestPosition(
        lat: 45.0,
        lon: -90.0,
      );

      final service = FakeLocationService(
        onGetCurrentLocation: () async => expectedPosition,
      );

      // Act
      final result = await service.getCurrentLocation();

      // Assert
      expect(result, isNotNull);
      final position = result!;
      expect(position.latitude, equals(45.0));
      expect(position.longitude, equals(-90.0));
    });

    test('returns false for isLocationServiceEnabled by default', () async {
      // Arrange
      final service = FakeLocationService();

      // Act
      final result = await service.isLocationServiceEnabled();

      // Assert
      expect(result, isFalse);
    });

    test('returns configured value for isLocationServiceEnabled', () async {
      // Arrange
      final service = FakeLocationService(
        onIsLocationServiceEnabled: () async => true,
      );

      // Act
      final result = await service.isLocationServiceEnabled();

      // Assert
      expect(result, isTrue);
    });

    test('can capture call arguments', () async {
      // Arrange
      var callCount = 0;
      final service = FakeLocationService(
        onRequestPermission: () async {
          callCount++;
          return true;
        },
      );

      // Act
      await service.requestPermission();
      await service.requestPermission();

      // Assert
      expect(callCount, equals(2));
    });

    group('permission denied scenarios', () {
      test(
        'getCurrentLocation returns null when permission denied',
        () async {
          // Arrange
          final service = FakeLocationService(
            onHasPermission: () async => false,
            onIsLocationServiceEnabled: () async => true,
          );

          // Act
          final result = await service.getCurrentLocation();

          // Assert
          expect(result, isNull);
        },
      );

      test(
        'requestPermission returns false when permission denied or services disabled',
        () async {
          // Test permission denied
          final serviceDenied = FakeLocationService(
            onRequestPermission: () async => false,
          );
          expect(await serviceDenied.requestPermission(), isFalse);

          // Test services disabled
          final serviceDisabled = FakeLocationService(
            onIsLocationServiceEnabled: () async => false,
            onRequestPermission: () async => false,
          );
          expect(await serviceDisabled.requestPermission(), isFalse);
        },
      );
    });

    group('location service disabled scenarios', () {
      test(
        'getCurrentLocation returns null when location services disabled',
        () async {
          // Arrange
          final service = FakeLocationService(
            onIsLocationServiceEnabled: () async => false,
            onHasPermission: () async => true,
          );

          // Act
          final result = await service.getCurrentLocation();

          // Assert
          expect(result, isNull);
        },
      );
    });

    group('successful scenarios', () {
      test(
        'getCurrentLocation returns position when all conditions met',
        () async {
          // Arrange
          final expectedPosition = createTestPosition(
            lat: 52.1993,
            lon: 0.1390,
          );

          final service = FakeLocationService(
            onIsLocationServiceEnabled: () async => true,
            onHasPermission: () async => true,
            onGetCurrentLocation: () async => expectedPosition,
          );

          // Act
          final result = await service.getCurrentLocation();

          // Assert
          expect(result, isNotNull);
          final position = result!;
          expect(position.latitude, equals(52.1993));
          expect(position.longitude, equals(0.1390));
        },
      );

      test('requestPermission returns true when granted', () async {
        // Arrange
        final service = FakeLocationService(
          onIsLocationServiceEnabled: () async => true,
          onRequestPermission: () async => true,
        );

        // Act
        final result = await service.requestPermission();

        // Assert
        expect(result, isTrue);
      });
    });
  });
}

