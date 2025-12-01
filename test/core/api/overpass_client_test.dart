import 'dart:convert';

import 'package:dartvcr/dartvcr.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldfish/core/api/http_client.dart';
import 'package:goldfish/core/api/overpass_client.dart';
import 'package:goldfish/core/data/models/place_suggestion_model.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('OverpassClient', () {
    setUp(() {
      // Setup is done per test as needed
    });

    group('findNearbyPlaces', () {
      test('successfully finds places and parses response', () async {
        // Arrange: Use a real location (Cambridge, UK) for recording
        const latitude = 52.1993;
        const longitude = 0.1390;
        const radiusMeters = 20.0;

        // Use dartvcr to record/replay real Overpass API responses
        final cassette = Cassette(
          'test/cassettes',
          'overpass_cambridge_places',
        );

        // Create a DartVCRClient that wraps http.Client
        final vcrClient = DartVCRClient(cassette, Mode.auto);
        final vcrHttpClient = HttpPackageClient(client: vcrClient);
        final vcrOverpassClient = OverpassClient(httpClient: vcrHttpClient);

        // Act
        final suggestions = await vcrOverpassClient.findNearbyPlaces(
          latitude,
          longitude,
          radiusMeters: radiusMeters,
        );

        // Assert
        expect(suggestions, isA<List<PlaceSuggestion>>());
        // Note: Results may vary, but we should get valid PlaceSuggestion
        // objects if any places are found
        for (final suggestion in suggestions) {
          expect(suggestion.name, isNotEmpty);
          expect(suggestion.latitude, isA<double>());
          expect(suggestion.longitude, isA<double>());
          expect(suggestion.tags, isA<Map<String, String>>());
        }
      });

      test('handles empty results gracefully', () async {
        // Arrange: Use a location in the middle of the ocean (no places)
        const latitude = 0.0;
        const longitude = 0.0;
        const radiusMeters = 20.0;

        final cassette = Cassette(
          'test/cassettes',
          'overpass_empty_results',
        );

        final vcrClient = DartVCRClient(cassette, Mode.auto);
        final vcrHttpClient = HttpPackageClient(client: vcrClient);
        final vcrOverpassClient = OverpassClient(httpClient: vcrHttpClient);

        // Act
        final suggestions = await vcrOverpassClient.findNearbyPlaces(
          latitude,
          longitude,
          radiusMeters: radiusMeters,
        );

        // Assert
        expect(suggestions, isEmpty);
      });

      test('parses different element types (node, way, relation)', () async {
        // Arrange: Mock response with different element types
        final mockResponse = {
          'elements': [
            {
              'type': 'node',
              'id': 123,
              'lat': 52.1993,
              'lon': 0.1390,
              'tags': {
                'name': 'Test Node',
                'amenity': 'pub',
              },
            },
            {
              'type': 'way',
              'id': 456,
              'center': {
                'lat': 52.1994,
                'lon': 0.1391,
              },
              'tags': {
                'name': 'Test Way',
                'shop': 'bakery',
              },
            },
            {
              'type': 'relation',
              'id': 789,
              'center': {
                'lat': 52.1995,
                'lon': 0.1392,
              },
              'tags': {
                'name': 'Test Relation',
                'tourism': 'museum',
              },
            },
          ],
        };

        final mockClient = MockClient((request) async {
          return http.Response(jsonEncode(mockResponse), 200);
        });

        final mockHttpClient = HttpPackageClient(client: mockClient);
        final mockOverpassClient = OverpassClient(httpClient: mockHttpClient);

        // Act
        final suggestions = await mockOverpassClient.findNearbyPlaces(
          52.1993,
          0.1390,
        );

        // Assert
        expect(suggestions, hasLength(3));
        expect(suggestions[0].name, 'Test Node');
        expect(suggestions[0].amenityType, 'amenity:pub');
        expect(suggestions[0].latitude, 52.1993);
        expect(suggestions[0].longitude, 0.1390);

        expect(suggestions[1].name, 'Test Way');
        expect(suggestions[1].amenityType, 'shop:bakery');
        expect(suggestions[1].latitude, 52.1994);
        expect(suggestions[1].longitude, 0.1391);

        expect(suggestions[2].name, 'Test Relation');
        expect(suggestions[2].amenityType, 'tourism:museum');
        expect(suggestions[2].latitude, 52.1995);
        expect(suggestions[2].longitude, 0.1392);
      });

      test('throws OverpassException on API error response', () async {
        // Arrange: Mock response with Overpass error
        final mockErrorResponse = {
          'remark': 'Runtime error: Query timed out',
        };

        final mockClient = MockClient((request) async {
          return http.Response(jsonEncode(mockErrorResponse), 200);
        });

        final mockHttpClient = HttpPackageClient(client: mockClient);
        final mockOverpassClient = OverpassClient(httpClient: mockHttpClient);

        // Act & Assert
        expect(
          () => mockOverpassClient.findNearbyPlaces(52.1993, 0.1390),
          throwsA(isA<OverpassException>()),
        );
      });

      test('throws OverpassException on HTTP error status', () async {
        // Arrange
        final mockClient = MockClient((request) async {
          return http.Response('Internal Server Error', 500);
        });

        final mockHttpClient = HttpPackageClient(client: mockClient);
        final mockOverpassClient = OverpassClient(httpClient: mockHttpClient);

        // Act & Assert
        expect(
          () => mockOverpassClient.findNearbyPlaces(52.1993, 0.1390),
          throwsA(isA<OverpassException>()),
        );
      });

      test('throws OverpassException on empty response', () async {
        // Arrange
        final mockClient = MockClient((request) async {
          return http.Response('', 200);
        });

        final mockHttpClient = HttpPackageClient(client: mockClient);
        final mockOverpassClient = OverpassClient(httpClient: mockHttpClient);

        // Act & Assert
        expect(
          () => mockOverpassClient.findNearbyPlaces(52.1993, 0.1390),
          throwsA(isA<OverpassException>()),
        );
      });

      test('throws OverpassException on invalid JSON response', () async {
        // Arrange
        final mockClient = MockClient((request) async {
          return http.Response('Invalid JSON {', 200);
        });

        final mockHttpClient = HttpPackageClient(client: mockClient);
        final mockOverpassClient = OverpassClient(httpClient: mockHttpClient);

        // Act & Assert
        expect(
          () => mockOverpassClient.findNearbyPlaces(52.1993, 0.1390),
          throwsA(isA<OverpassException>()),
        );
      });

      test('propagates network errors', () async {
        // Arrange
        final mockClient = MockClient((request) {
          throw http.ClientException('Network error');
        });

        final mockHttpClient = HttpPackageClient(client: mockClient);
        final mockOverpassClient = OverpassClient(httpClient: mockHttpClient);

        // Act & Assert
        expect(
          () => mockOverpassClient.findNearbyPlaces(52.1993, 0.1390),
          throwsA(isA<http.ClientException>()),
        );
      });

      test('uses custom radius when provided', () async {
        // Arrange
        const customRadius = 50.0;
        final capturedQueries = <String>[];

        final mockClient = MockClient((request) async {
          capturedQueries.add(request.body);
          return http.Response(
            jsonEncode({'elements': []}),
            200,
          );
        });

        final mockHttpClient = HttpPackageClient(client: mockClient);
        final mockOverpassClient = OverpassClient(httpClient: mockHttpClient);

        // Act
        await mockOverpassClient.findNearbyPlaces(
          52.1993,
          0.1390,
          radiusMeters: customRadius,
        );

        // Assert
        expect(capturedQueries, hasLength(1));
        expect(capturedQueries.first, contains('around:$customRadius'));
      });

      test('uses custom base URL when provided', () async {
        // Arrange
        final capturedUrls = <Uri>[];

        final mockClient = MockClient((request) async {
          capturedUrls.add(request.url);
          return http.Response(
            jsonEncode({'elements': []}),
            200,
          );
        });

        const customBaseUrl = 'https://custom-overpass.example.com/api';
        final mockHttpClient = HttpPackageClient(client: mockClient);
        final customOverpassClient = OverpassClient(
          httpClient: mockHttpClient,
          baseUrl: customBaseUrl,
        );

        // Act
        await customOverpassClient.findNearbyPlaces(52.1993, 0.1390);

        // Assert
        expect(capturedUrls, hasLength(1));
        expect(capturedUrls.first.toString(), customBaseUrl);
      });
    });

    group('_buildQuery', () {
      test('builds correct Overpass query format', () async {
        // This is an indirect test through findNearbyPlaces
        // We verify the query structure by checking what gets sent
        final capturedBodies = <String>[];

        final mockClient = MockClient((request) async {
          capturedBodies.add(request.body);
          return http.Response(
            jsonEncode({'elements': []}),
            200,
          );
        });

        final mockHttpClient = HttpPackageClient(client: mockClient);
        final mockOverpassClient = OverpassClient(httpClient: mockHttpClient);

        // Act
        await mockOverpassClient.findNearbyPlaces(
          52.1993,
          0.1390,
          radiusMeters: 20,
        );

        // Assert - verify query structure
        expect(capturedBodies, hasLength(1));
        final query = capturedBodies.first;

        // Check query contains required components
        expect(query, contains('[out:json]'));
        expect(query, contains('[timeout:25]'));
        expect(query, contains('node(around:20'));
        expect(query, contains('way(around:20'));
        expect(query, contains('relation(around:20'));
        expect(query, contains('out center tags'));
        expect(query, contains('amenity'));
        expect(query, contains('tourism'));
        expect(query, contains('shop'));
      });
    });
  });
}

