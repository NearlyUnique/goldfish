import 'dart:convert';

import 'package:goldfish/core/api/http_client.dart';
import 'package:goldfish/core/data/models/place_suggestion_model.dart';
import 'package:goldfish/core/logging/app_logger.dart';
import 'package:http/http.dart' as http;

/// Exception thrown when Overpass API returns an error.
class OverpassException implements Exception {
  /// Creates a new [OverpassException].
  const OverpassException(this.message, [this.statusCode]);

  /// The error message from the API.
  final String message;

  /// The HTTP status code, if available.
  final int? statusCode;

  @override
  String toString() => 'OverpassException: $message';
}

/// Client for querying the Overpass API to find nearby places.
///
/// The Overpass API provides access to OpenStreetMap data. This client
/// queries for places (amenities, shops, tourism, etc.) within a specified
/// radius of a GPS location.
class OverpassClient {
  /// Creates a new [OverpassClient].
  ///
  /// Requires an [httpClient] for making HTTP requests. Optionally accepts
  /// a custom [baseUrl] for the Overpass API endpoint.
  OverpassClient({
    required HttpClient httpClient,
    String baseUrl = 'https://overpass-api.de/api/interpreter',
  }) : _httpClient = httpClient,
       _baseUrl = baseUrl;

  final HttpClient _httpClient;
  final String _baseUrl;

  /// Finds nearby places within the specified radius of the given coordinates.
  ///
  /// Queries the Overpass API for nodes, ways, and relations that match
  /// amenity/tourism/historic/leisure/shop/craft/office/public_transport tags
  /// within [radiusMeters] of the location.
  ///
  /// Returns a list of [PlaceSuggestion] objects parsed from the API response.
  /// Returns an empty list if no places are found.
  ///
  /// Throws [OverpassException] if the API request fails or returns an error.
  /// Throws [http.ClientException] if there is a network error.
  Future<List<PlaceSuggestion>> findNearbyPlaces(
    double latitude,
    double longitude, {
    double radiusMeters = 20,
  }) async {
    try {
      final query = _buildQuery(latitude, longitude, radiusMeters);
      final uri = Uri.parse(_baseUrl);

      final response = await _httpClient.post(
        uri,
        headers: {'Content-Type': 'text/plain'},
        body: query,
      );

      if (response.statusCode != 200) {
        AppLogger.error({
          'event': 'overpass_api_error',
          'status_code': response.statusCode,
          'latitude': latitude,
          'longitude': longitude,
        });
        throw OverpassException(
          'Overpass API returned status ${response.statusCode}',
          response.statusCode,
        );
      }

      final responseBody = response.body;
      if (responseBody.isEmpty) {
        AppLogger.error({
          'event': 'overpass_api_empty_response',
          'latitude': latitude,
          'longitude': longitude,
        });
        throw const OverpassException('Overpass API returned empty response');
      }

      final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;

      // Check for Overpass API errors in the response
      if (jsonResponse.containsKey('remark')) {
        final remark = jsonResponse['remark'] as String?;
        AppLogger.error({
          'event': 'overpass_api_error',
          'remark': remark ?? 'Unknown error',
          'latitude': latitude,
          'longitude': longitude,
        });
        throw OverpassException(
          'Overpass API error: ${remark ?? 'Unknown error'}',
        );
      }

      if (jsonResponse.containsKey('elements') == false) {
        AppLogger.error({
          'event': 'overpass_api_invalid_response',
          'latitude': latitude,
          'longitude': longitude,
        });
        throw const OverpassException(
          'Overpass API response missing elements array',
        );
      }

      final suggestions = PlaceSuggestion.fromOverpassResponse(jsonResponse);

      return suggestions;
    } on FormatException catch (e) {
      AppLogger.error({
        'event': 'overpass_api_parse_error',
        'error': e.toString(),
        'latitude': latitude,
        'longitude': longitude,
      });
      throw OverpassException('Failed to parse Overpass API response: $e');
    } on http.ClientException catch (e) {
      AppLogger.error({
        'event': 'overpass_api_network_error',
        'error': e.toString(),
        'latitude': latitude,
        'longitude': longitude,
      });
      // Re-throw network errors as-is
      rethrow;
    } on OverpassException {
      // Already logged above, re-throw as-is
      rethrow;
    } catch (e) {
      AppLogger.error({
        'event': 'overpass_api_unexpected_error',
        'error': e.toString(),
        'latitude': latitude,
        'longitude': longitude,
      });
      throw OverpassException('Unexpected error: $e');
    }
  }

  /// Builds an Overpass QL query string for finding nearby places.
  ///
  /// The query searches for nodes, ways, and relations within [radiusMeters]
  /// of the given coordinates, filtering by amenity/tourism/historic/leisure/
  /// shop/craft/office/public_transport tags.
  String _buildQuery(double lat, double lon, double radius) {
    // Overpass QL query to find places within radius
    // Filters by common place tags: amenity, tourism, historic, leisure,
    // shop, craft, office, public_transport
    // Note: The regex pattern uses ~ operator to match tag keys
    final subQuery =
        'around:$radius,$lat,$lon)[~"^(amenity|tourism|historic|leisure|shop|craft|office|public_transport)\$"~"."]';
    final query =
        '[out:json][timeout:25];(node($subQuery);way($subQuery);relation($subQuery));out center tags;';

    return query.trim();
  }
}
