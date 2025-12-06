import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:goldfish/core/api/overpass_client.dart';
import 'package:goldfish/core/data/models/place_suggestion_model.dart';
import 'package:http/http.dart' as http;

import 'test_helpers.dart';

void main() {
  group('OverpassClient', () {
    group('findNearbyPlaces', () {
      test('successfully finds places and parses response', () async {
        // Arrange: Use example coordinates
        const latitude = 45.0;
        const longitude = -90.0;
        const radiusMeters = 20.0;

        final mockResponse = {
          'elements': [
            {
              'type': 'node',
              'id': 123,
              'lat': 45.0,
              'lon': -90.0,
              'tags': {'name': 'Example Place', 'amenity': 'cafe'},
            },
          ],
        };

        final mockOverpassClient = createMockOverpassClient(
          response: http.Response(jsonEncode(mockResponse), 200),
        );

        // Act
        final suggestions = await mockOverpassClient.findNearbyPlaces(
          latitude,
          longitude,
          radiusMeters: radiusMeters,
        );

        // Assert
        expect(suggestions, isA<List<PlaceSuggestion>>());
        expect(suggestions, hasLength(1));
        expect(suggestions[0].name, 'Example Place');
        expect(suggestions[0].latitude, 45.0);
        expect(suggestions[0].longitude, -90.0);
        expect(suggestions[0].tags, isA<Map<String, String>>());
      });

      test('handles empty results gracefully', () async {
        // Arrange: Use example coordinates with empty results
        const latitude = 45.0;
        const longitude = -90.0;
        const radiusMeters = 20.0;

        final mockOverpassClient = createMockOverpassClient(
          response: http.Response(jsonEncode({'elements': []}), 200),
        );

        // Act
        final suggestions = await mockOverpassClient.findNearbyPlaces(
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
              'lat': 45.0,
              'lon': -90.0,
              'tags': {'name': 'Test Node', 'amenity': 'pub'},
            },
            {
              'type': 'way',
              'id': 456,
              'center': {'lat': 45.1, 'lon': -90.1},
              'tags': {'name': 'Test Way', 'shop': 'bakery'},
            },
            {
              'type': 'relation',
              'id': 789,
              'center': {'lat': 45.2, 'lon': -90.2},
              'tags': {'name': 'Test Relation', 'tourism': 'museum'},
            },
          ],
        };

        final mockOverpassClient = createMockOverpassClient(
          response: http.Response(jsonEncode(mockResponse), 200),
        );

        // Act
        final suggestions = await mockOverpassClient.findNearbyPlaces(
          45.0,
          -90.0,
        );

        // Assert
        expect(suggestions, hasLength(3));
        expect(suggestions[0].name, 'Test Node');
        expect(suggestions[0].amenityType, 'amenity:pub');
        expect(suggestions[0].latitude, 45.0);
        expect(suggestions[0].longitude, -90.0);

        expect(suggestions[1].name, 'Test Way');
        expect(suggestions[1].amenityType, 'shop:bakery');
        expect(suggestions[1].latitude, 45.1);
        expect(suggestions[1].longitude, -90.1);

        expect(suggestions[2].name, 'Test Relation');
        expect(suggestions[2].amenityType, 'tourism:museum');
        expect(suggestions[2].latitude, 45.2);
        expect(suggestions[2].longitude, -90.2);
      });

      test('throws OverpassException on API error response', () async {
        // Arrange: Mock response with Overpass error
        final mockErrorResponse = {'remark': 'Runtime error: Query timed out'};

        final mockOverpassClient = createMockOverpassClient(
          response: http.Response(jsonEncode(mockErrorResponse), 200),
        );

        // Act & Assert
        expect(
          () => mockOverpassClient.findNearbyPlaces(45.0, -90.0),
          throwsA(isA<OverpassException>()),
        );
      });

      test('throws OverpassException on HTTP error status', () async {
        // Arrange
        final mockOverpassClient = createMockOverpassClient(
          response: http.Response('Internal Server Error', 500),
        );

        // Act & Assert
        expect(
          () => mockOverpassClient.findNearbyPlaces(45.0, -90.0),
          throwsA(isA<OverpassException>()),
        );
      });

      test('throws OverpassException on empty response', () async {
        // Arrange
        final mockOverpassClient = createMockOverpassClient(
          response: http.Response('', 200),
        );

        // Act & Assert
        expect(
          () => mockOverpassClient.findNearbyPlaces(45.0, -90.0),
          throwsA(isA<OverpassException>()),
        );
      });

      test('throws OverpassException on invalid JSON response', () async {
        // Arrange
        final mockOverpassClient = createMockOverpassClient(
          response: http.Response('Invalid JSON {', 200),
        );

        // Act & Assert
        expect(
          () => mockOverpassClient.findNearbyPlaces(45.0, -90.0),
          throwsA(isA<OverpassException>()),
        );
      });

      test('propagates network errors', () async {
        // Arrange
        final mockClient = createThrowingMockClient(
          exception: http.ClientException('Network error'),
        );
        final mockOverpassClient = createMockOverpassClient(
          mockClient: mockClient,
        );

        // Act & Assert
        expect(
          () => mockOverpassClient.findNearbyPlaces(45.0, -90.0),
          throwsA(isA<http.ClientException>()),
        );
      });

      test('uses custom radius when provided', () async {
        // Arrange
        const customRadius = 50.0;
        final capturedQueries = <String>[];

        final mockClient = createCapturingMockClient(
          response: http.Response(jsonEncode({'elements': []}), 200),
          onRequest: (request) {
            capturedQueries.add(request.body);
          },
        );
        final mockOverpassClient = createMockOverpassClient(
          mockClient: mockClient,
        );

        // Act
        await mockOverpassClient.findNearbyPlaces(
          45.0,
          -90.0,
          radiusMeters: customRadius,
        );

        // Assert
        expect(capturedQueries, hasLength(1));
        expect(capturedQueries.first, contains('around:$customRadius'));
      });

      test('uses custom base URL when provided', () async {
        // Arrange
        final capturedUrls = <Uri>[];

        final mockClient = createCapturingMockClient(
          response: http.Response(jsonEncode({'elements': []}), 200),
          onRequest: (request) {
            capturedUrls.add(request.url);
          },
        );
        const customBaseUrl = 'https://custom-overpass.example.com/api';
        final mockHttpClient = createMockHttpClient(mockClient: mockClient);
        final customOverpassClient = OverpassClient(
          httpClient: mockHttpClient,
          baseUrl: customBaseUrl,
        );

        // Act
        await customOverpassClient.findNearbyPlaces(45.0, -90.0);

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

        final mockClient = createCapturingMockClient(
          response: http.Response(jsonEncode({'elements': []}), 200),
          onRequest: (request) {
            capturedBodies.add(request.body);
          },
        );
        final mockOverpassClient = createMockOverpassClient(
          mockClient: mockClient,
        );

        // Act
        await mockOverpassClient.findNearbyPlaces(
          45.0,
          -90.0,
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
