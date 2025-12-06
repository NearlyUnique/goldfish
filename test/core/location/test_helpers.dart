import 'package:geolocator/geolocator.dart';
import 'package:goldfish/core/location/location_service.dart';
import '../../fakes/geolocator_wrapper_fake.dart';

/// Creates a test [Position] with the given latitude and longitude.
///
/// All other fields are set to default test values.
Position createTestPosition({required double lat, required double lon}) {
  return Position(
    latitude: lat,
    longitude: lon,
    timestamp: DateTime.now(),
    accuracy: 10.0,
    altitude: 0.0,
    altitudeAccuracy: 0.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );
}

/// Creates a [GeolocatorLocationService] with a [FakeGeolocatorWrapper].
GeolocatorLocationService createLocationServiceWithWrapper(
  FakeGeolocatorWrapper wrapper,
) {
  return GeolocatorLocationService(geolocatorWrapper: wrapper);
}
