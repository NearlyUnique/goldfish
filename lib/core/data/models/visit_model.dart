import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a geographic coordinate (latitude and longitude).
class GeoLatLong {
  /// Creates a new [GeoLatLong].
  const GeoLatLong({required this.lat, required this.long});

  /// Creates a [GeoLatLong] from a map (typically from Firestore).
  factory GeoLatLong.fromMap(Map<String, dynamic> map) {
    return GeoLatLong(
      lat: (map['lat'] as num).toDouble(),
      long: (map['long'] as num).toDouble(),
    );
  }

  /// The latitude coordinate.
  final double lat;

  /// The longitude coordinate.
  final double long;

  /// Converts this [GeoLatLong] to a map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {'lat': lat, 'long': long};
  }

  /// Creates a copy of this [GeoLatLong] with the given fields replaced.
  GeoLatLong copyWith({double? lat, double? long}) {
    return GeoLatLong(lat: lat ?? this.lat, long: long ?? this.long);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeoLatLong && other.lat == lat && other.long == long;
  }

  @override
  int get hashCode => Object.hash(lat, long);

  @override
  String toString() => 'GeoLatLong(lat: $lat, long: $long)';
}

/// Represents the type of a location (e.g., amenity: pub).
class LocationType {
  /// Creates a new [LocationType].
  const LocationType({required this.type, required this.subType});

  /// Creates a [LocationType] from a map (typically from Firestore).
  factory LocationType.fromMap(Map<String, dynamic> map) {
    return LocationType(
      type: map['type'] as String,
      subType: map['sub_type'] as String,
    );
  }

  /// The main type (e.g., 'amenity', 'tourism', 'shop').
  final String type;

  /// The subtype (e.g., 'pub', 'restaurant', 'cafe').
  final String subType;

  /// Converts this [LocationType] to a map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {'type': type, 'sub_type': subType};
  }

  /// Creates a copy of this [LocationType] with the given fields replaced.
  LocationType copyWith({String? type, String? subType}) {
    return LocationType(
      type: type ?? this.type,
      subType: subType ?? this.subType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationType &&
        other.type == type &&
        other.subType == subType;
  }

  @override
  int get hashCode => Object.hash(type, subType);

  @override
  String toString() => 'LocationType(type: $type, subType: $subType)';
}

/// Represents a physical address.
class Address {
  /// Creates a new [Address].
  const Address({this.nameNumber, this.street, this.city, this.postcode});

  /// Creates an [Address] from a map (typically from Firestore).
  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      nameNumber: map['name_number'] as String?,
      street: map['street'] as String?,
      city: map['city'] as String?,
      postcode: map['postcode'] as String?,
    );
  }

  /// The house/building name or number.
  final String? nameNumber;

  /// The street name.
  final String? street;

  /// The city name.
  final String? city;

  /// The postal code.
  final String? postcode;

  /// Converts this [Address] to a map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'name_number': nameNumber,
      'street': street,
      'city': city,
      'postcode': postcode,
    };
  }

  /// Creates a copy of this [Address] with the given fields replaced.
  Address copyWith({
    String? nameNumber,
    String? street,
    String? city,
    String? postcode,
  }) {
    return Address(
      nameNumber: nameNumber ?? this.nameNumber,
      street: street ?? this.street,
      city: city ?? this.city,
      postcode: postcode ?? this.postcode,
    );
  }

  /// Returns a formatted address string.
  String toFormattedString() {
    final parts = <String>[];
    if (nameNumber != null && nameNumber!.isNotEmpty) {
      parts.add(nameNumber!);
    }
    if (street != null && street!.isNotEmpty) {
      parts.add(street!);
    }
    if (city != null && city!.isNotEmpty) {
      parts.add(city!);
    }
    if (postcode != null && postcode!.isNotEmpty) {
      parts.add(postcode!);
    }
    return parts.join(', ');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Address &&
        other.nameNumber == nameNumber &&
        other.street == street &&
        other.city == city &&
        other.postcode == postcode;
  }

  @override
  int get hashCode => Object.hash(nameNumber, street, city, postcode);

  @override
  String toString() => 'Address(${toFormattedString()})';
}

/// Visit model representing a recorded visit to a location.
///
/// Contains all information about a visit including location, place details,
/// and metadata.
class Visit {
  /// Creates a new [Visit].
  const Visit({
    this.id,
    required this.userId,
    required this.placeName,
    this.placeAddress,
    this.gpsRecorded,
    this.gpsKnown,
    this.placeType,
    required this.addedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [Visit] from a Firestore document snapshot.
  factory Visit.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Visit(
      id: doc.id,
      userId: data['user_id'] as String,
      placeName: data['place_name'] as String,
      placeAddress: data['place_address'] != null
          ? Address.fromMap(data['place_address'] as Map<String, dynamic>)
          : null,
      gpsRecorded: data['gps_recorded'] != null
          ? GeoLatLong.fromMap(data['gps_recorded'] as Map<String, dynamic>)
          : null,
      gpsKnown: data['gps_known'] != null
          ? GeoLatLong.fromMap(data['gps_known'] as Map<String, dynamic>)
          : null,
      placeType: data['place_type'] != null
          ? LocationType.fromMap(data['place_type'] as Map<String, dynamic>)
          : null,
      addedAt: (data['added_at'] as Timestamp).toDate(),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  /// Creates a [Visit] from a map (typically from Firestore).
  factory Visit.fromMap(Map<String, dynamic> map, String id) {
    return Visit(
      id: id,
      userId: map['user_id'] as String,
      placeName: map['place_name'] as String,
      placeAddress: map['place_address'] != null
          ? Address.fromMap(map['place_address'] as Map<String, dynamic>)
          : null,
      gpsRecorded: map['gps_recorded'] != null
          ? GeoLatLong.fromMap(map['gps_recorded'] as Map<String, dynamic>)
          : null,
      gpsKnown: map['gps_known'] != null
          ? GeoLatLong.fromMap(map['gps_known'] as Map<String, dynamic>)
          : null,
      placeType: map['place_type'] != null
          ? LocationType.fromMap(map['place_type'] as Map<String, dynamic>)
          : null,
      addedAt: (map['added_at'] as Timestamp).toDate(),
      createdAt: (map['created_at'] as Timestamp).toDate(),
      updatedAt: (map['updated_at'] as Timestamp).toDate(),
    );
  }

  /// The Firestore document ID (null for new visits).
  final String? id;

  /// The logged-in user's UID.
  final String userId;

  /// The name of the place visited (required).
  final String placeName;

  /// The physical address of the place (optional).
  final Address? placeAddress;

  /// The GPS coordinates where the user was when recording the visit.
  final GeoLatLong? gpsRecorded;

  /// The GPS coordinates of the place from Overpass API (optional).
  final GeoLatLong? gpsKnown;

  /// The type of place from Overpass tags (e.g., amenity: pub).
  final LocationType? placeType;

  /// The date and time when the visit was added.
  final DateTime addedAt;

  /// When the visit record was created.
  final DateTime createdAt;

  /// When the visit record was last updated.
  final DateTime updatedAt;

  /// Converts this [Visit] to a map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'place_name': placeName,
      'place_address': placeAddress?.toMap(),
      'gps_recorded': gpsRecorded?.toMap(),
      'gps_known': gpsKnown?.toMap(),
      'place_type': placeType?.toMap(),
      'added_at': Timestamp.fromDate(addedAt),
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  /// Creates a copy of this [Visit] with the given fields replaced.
  Visit copyWith({
    String? id,
    String? userId,
    String? placeName,
    Address? placeAddress,
    GeoLatLong? gpsRecorded,
    GeoLatLong? gpsKnown,
    LocationType? placeType,
    DateTime? addedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Visit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      placeName: placeName ?? this.placeName,
      placeAddress: placeAddress ?? this.placeAddress,
      gpsRecorded: gpsRecorded ?? this.gpsRecorded,
      gpsKnown: gpsKnown ?? this.gpsKnown,
      placeType: placeType ?? this.placeType,
      addedAt: addedAt ?? this.addedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Validates that required fields are present.
  ///
  /// Returns a list of validation error messages, empty if valid.
  List<String> validate() {
    final errors = <String>[];
    if (placeName.trim().isEmpty) {
      errors.add('Place name is required');
    }
    if (userId.trim().isEmpty) {
      errors.add('User ID is required');
    }
    return errors;
  }

  /// Returns true if this visit is valid.
  bool get isValid => validate().isEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Visit &&
        other.id == id &&
        other.userId == userId &&
        other.placeName == placeName &&
        other.placeAddress == placeAddress &&
        other.gpsRecorded == gpsRecorded &&
        other.gpsKnown == gpsKnown &&
        other.placeType == placeType &&
        other.addedAt == addedAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      placeName,
      placeAddress,
      gpsRecorded,
      gpsKnown,
      placeType,
      addedAt,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Visit(id: $id, placeName: $placeName, userId: $userId)';
  }
}
