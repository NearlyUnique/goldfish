/// Model for place suggestions from Overpass API.
///
/// Represents a place found near a GPS location, with information extracted
/// from OpenStreetMap data via the Overpass API.
class PlaceSuggestion {
  /// Creates a new [PlaceSuggestion].
  const PlaceSuggestion({
    required this.name,
    this.amenityType,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.tags,
  });

  /// Creates a [PlaceSuggestion] from an Overpass API element.
  ///
  /// Handles different element types (node, way, relation) and extracts
  /// coordinates appropriately. For ways and relations, uses center coordinates.
  factory PlaceSuggestion.fromOverpassElement(Map<String, dynamic> element) {
    final tags = Map<String, String>.from(
      element['tags'] as Map<String, dynamic>? ?? {},
    );

    // Extract name - use name tag, fallback to other name variants
    final name = _extractName(tags);

    // Extract amenity type from various tag keys
    final amenityType = _extractAmenityType(tags);

    // Extract coordinates based on element type
    double latitude;
    double longitude;

    if (element['type'] == 'node') {
      // Nodes have direct lat/lon
      latitude = (element['lat'] as num).toDouble();
      longitude = (element['lon'] as num).toDouble();
    } else if (element['type'] == 'way' || element['type'] == 'relation') {
      // Ways and relations have center coordinates
      final center = element['center'] as Map<String, dynamic>?;
      if (center != null) {
        latitude = (center['lat'] as num).toDouble();
        longitude = (center['lon'] as num).toDouble();
      } else {
        // Fallback: try to get from geometry if available
        final geometry = element['geometry'] as List<dynamic>?;
        if (geometry != null && geometry.isNotEmpty) {
          // Use first point as approximation
          final firstPoint = geometry[0] as Map<String, dynamic>;
          latitude = (firstPoint['lat'] as num).toDouble();
          longitude = (firstPoint['lon'] as num).toDouble();
        } else {
          throw ArgumentError(
            'Element ${element['type']} missing center or geometry',
          );
        }
      }
    } else {
      throw ArgumentError('Unknown element type: ${element['type']}');
    }

    // Extract address from addr:* tags
    final address = _extractAddress(tags);

    return PlaceSuggestion(
      name: name,
      amenityType: amenityType,
      latitude: latitude,
      longitude: longitude,
      address: address,
      tags: tags,
    );
  }

  /// Creates a list of [PlaceSuggestion] from an Overpass API response.
  ///
  /// Parses the JSON response and converts all elements to PlaceSuggestion
  /// objects. Filters out elements that cannot be parsed.
  static List<PlaceSuggestion> fromOverpassResponse(
    Map<String, dynamic> response,
  ) {
    final elements = response['elements'] as List<dynamic>?;
    if (elements == null) {
      return [];
    }

    final suggestions = <PlaceSuggestion>[];

    for (final element in elements) {
      try {
        final suggestion = PlaceSuggestion.fromOverpassElement(
          element as Map<String, dynamic>,
        );
        suggestions.add(suggestion);
      } catch (e) {
        // Skip elements that cannot be parsed
        // In production, you might want to log this
        continue;
      }
    }

    return suggestions;
  }

  /// The name of the place.
  ///
  /// Extracted from name tag or fallback variants. Never empty (uses
  /// "Unnamed Place" as fallback).
  final String name;

  /// The amenity type (e.g., 'amenity', 'tourism', 'shop').
  ///
  /// Extracted from tags like amenity, tourism, historic, leisure, shop,
  /// craft, office, or public_transport. Null if no type found.
  final String? amenityType;

  /// The latitude coordinate of the place.
  final double latitude;

  /// The longitude coordinate of the place.
  final double longitude;

  /// The formatted address string.
  ///
  /// Constructed from addr:* tags (addr:street, addr:housenumber, etc.).
  /// Null if no address information available.
  final String? address;

  /// All Overpass tags for this place.
  ///
  /// Contains all key-value pairs from the Overpass element tags.
  final Map<String, String> tags;

  /// Extracts the name from tags.
  ///
  /// Tries name, then name:en, then other variants. Returns "Unnamed Place"
  /// if no name found.
  static String _extractName(Map<String, String> tags) {
    // Try various name tags in order of preference
    final nameKeys = [
      'name',
      'name:en',
      'alt_name',
      'official_name',
      'short_name',
    ];

    for (final key in nameKeys) {
      final value = tags[key];
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    // Fallback to "Unnamed Place" if no name found
    return 'Unnamed Place';
  }

  /// Extracts the amenity type from tags.
  ///
  /// Checks for amenity, tourism, historic, leisure, shop, craft, office,
  /// and public_transport tags. Returns the key and value as "key:value"
  /// format, or null if no type found.
  static String? _extractAmenityType(Map<String, String> tags) {
    final typeKeys = [
      'amenity',
      'tourism',
      'historic',
      'leisure',
      'shop',
      'craft',
      'office',
      'public_transport',
    ];

    for (final key in typeKeys) {
      final value = tags[key];
      if (value != null && value.trim().isNotEmpty) {
        return '$key:${value.trim()}';
      }
    }

    return null;
  }

  /// Extracts and formats address from addr:* tags.
  ///
  /// Combines addr:housenumber, addr:street, addr:city, and addr:postcode
  /// into a formatted string. Returns null if no address information found.
  static String? _extractAddress(Map<String, String> tags) {
    final parts = <String>[];

    // Extract address components
    final houseNumber = tags['addr:housenumber'];
    final street = tags['addr:street'];
    final city = tags['addr:city'];
    final postcode = tags['addr:postcode'];

    // Build address string
    if (houseNumber != null && houseNumber.trim().isNotEmpty) {
      parts.add(houseNumber.trim());
    }
    if (street != null && street.trim().isNotEmpty) {
      parts.add(street.trim());
    }
    if (city != null && city.trim().isNotEmpty) {
      parts.add(city.trim());
    }
    if (postcode != null && postcode.trim().isNotEmpty) {
      parts.add(postcode.trim());
    }

    if (parts.isEmpty) {
      return null;
    }

    return parts.join(', ');
  }

  /// Creates a copy of this [PlaceSuggestion] with the given fields replaced.
  PlaceSuggestion copyWith({
    String? name,
    String? amenityType,
    double? latitude,
    double? longitude,
    String? address,
    Map<String, String>? tags,
  }) {
    return PlaceSuggestion(
      name: name ?? this.name,
      amenityType: amenityType ?? this.amenityType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlaceSuggestion &&
        other.name == name &&
        other.amenityType == amenityType &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.address == address &&
        _mapsEqual(other.tags, tags);
  }

  @override
  int get hashCode {
    return Object.hash(name, amenityType, latitude, longitude, address, tags);
  }

  @override
  String toString() {
    return 'PlaceSuggestion(name: $name, type: $amenityType, '
        'lat: $latitude, lon: $longitude)';
  }

  /// Helper method to compare maps for equality.
  bool _mapsEqual(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}
