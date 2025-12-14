import 'dart:convert';

import 'package:goldfish/core/api/http_client.dart';
import 'package:goldfish/core/data/models/place_suggestion_model.dart';
import 'package:goldfish/core/exceptions/goldfish_exception.dart';
import 'package:http/http.dart' as http;

/// Exception thrown when Overpass API returns an error.
class OverpassException extends GoldfishException {
  /// Creates a new [OverpassException] with the given [eventName] and optional
  /// context fields for logging.
  const OverpassException(
    String eventName, {
    this.statusCode,
    this.responseBody,
    this.remark,
    this.latitude,
    this.longitude,
    Object? innerError,
  }) : super(eventName, innerError);

  /// The HTTP status code, if available.
  final int? statusCode;

  /// The response body from the API, if available.
  final String? responseBody;

  /// The remark/error message from Overpass API, if available.
  final String? remark;

  /// The latitude used in the query, if available.
  final double? latitude;

  /// The longitude used in the query, if available.
  final double? longitude;

  /// Gets the display message for the exception including diagnostic fields
  @override
  String toString() {
    final parts = <String>['overpass: ${super.toString()}'];
    if (statusCode != null) parts.add('statusCode=$statusCode');
    if (remark != null) parts.add('remark=$remark');
    if (latitude != null && longitude != null) {
      parts.add('lat=$latitude, lon=$longitude');
    }
    return parts.join(', ');
  }
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
        throw OverpassException(
          'overpass_api_error',
          statusCode: response.statusCode,
          responseBody: response.body,
          latitude: latitude,
          longitude: longitude,
        );
      }

      final responseBody = response.body;
      if (responseBody.isEmpty) {
        throw OverpassException(
          'overpass_api_empty_response',
          latitude: latitude,
          longitude: longitude,
        );
      }

      final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;

      // Check for Overpass API errors in the response
      if (jsonResponse.containsKey('remark')) {
        final remark = jsonResponse['remark'] as String?;
        throw OverpassException(
          'overpass_api_error',
          remark: remark,
          latitude: latitude,
          longitude: longitude,
        );
      }

      if (!jsonResponse.containsKey('elements')) {
        throw OverpassException(
          'overpass_api_invalid_response',
          latitude: latitude,
          longitude: longitude,
        );
      }

      final suggestions = PlaceSuggestion.fromOverpassResponse(jsonResponse);

      return suggestions;
    } on FormatException catch (e) {
      throw OverpassException(
        'overpass_api_parse_error',
        latitude: latitude,
        longitude: longitude,
        innerError: e,
      );
    } on http.ClientException {
      // Re-throw network errors as-is
      rethrow;
    } on OverpassException {
      // Re-throw as-is
      rethrow;
    } catch (e) {
      throw OverpassException(
        'overpass_api_unexpected_error',
        latitude: latitude,
        longitude: longitude,
        innerError: e,
      );
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
    const filter =
        '[~"^(amenity|tourism|historic|leisure|shop|craft|office|public_transport)\$"~"."]';
    final query =
        '''[out:json][timeout:25];
(
  node(around:$radius,$lat,$lon)$filter;
  way(around:$radius,$lat,$lon)$filter;
  relation(around:$radius,$lat,$lon)$filter;
);
out center tags;''';

    return query;
  }
}
