import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:goldfish/core/location/geolocator_wrapper.dart';

/// Tests for [GeolocatorPackageWrapper].
///
/// Note: These tests verify that the wrapper correctly delegates to the
/// Geolocator package. Since Geolocator requires platform-specific setup,
/// these tests primarily verify the wrapper structure and that methods
/// are properly implemented. Full integration testing would require
/// platform-specific test setup.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('GeolocatorPackageWrapper', () {
    test('implements GeolocatorWrapper interface', () {
      // Arrange & Act
      const wrapper = GeolocatorPackageWrapper();

      // Assert
      expect(wrapper, isA<GeolocatorWrapper>());
    });

    test('has const constructor', () {
      // Arrange & Act
      const wrapper1 = GeolocatorPackageWrapper();
      const wrapper2 = GeolocatorPackageWrapper();

      // Assert - const constructors allow identical instances
      expect(wrapper1, equals(wrapper2));
    });

    test('checkPermission method exists and has correct signature', () {
      // Arrange
      const wrapper = GeolocatorPackageWrapper();

      // Act & Assert
      // Verify the method exists and returns the correct type
      // Note: We don't actually call it to avoid platform plugin requirements
      expect(wrapper.checkPermission, isA<Future<LocationPermission> Function()>());
    });

    test('requestPermission method exists and has correct signature', () {
      // Arrange
      const wrapper = GeolocatorPackageWrapper();

      // Act & Assert
      expect(wrapper.requestPermission, isA<Future<LocationPermission> Function()>());
    });

    test('getCurrentPosition method exists and has correct signature', () {
      // Arrange
      const wrapper = GeolocatorPackageWrapper();

      // Act & Assert
      expect(
        wrapper.getCurrentPosition,
        isA<Future<Position> Function({LocationSettings? locationSettings})>(),
      );
    });

    test('isLocationServiceEnabled method exists and has correct signature', () {
      // Arrange
      const wrapper = GeolocatorPackageWrapper();

      // Act & Assert
      expect(
        wrapper.isLocationServiceEnabled,
        isA<Future<bool> Function()>(),
      );
    });
  });
}

