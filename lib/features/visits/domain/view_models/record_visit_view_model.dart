import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:goldfish/core/api/overpass_client.dart';
import 'package:goldfish/core/auth/auth_notifier.dart';
import 'package:goldfish/core/data/models/place_suggestion_model.dart';
import 'package:goldfish/core/data/models/visit_model.dart';
import 'package:goldfish/core/data/repositories/visit_repository.dart';
import 'package:goldfish/core/data/visit_exceptions.dart';
import 'package:goldfish/core/location/location_service.dart';
import 'package:goldfish/core/logging/app_logger.dart';
import 'package:http/http.dart' as http;

/// ViewModel for managing the record visit screen state and business logic.
///
/// Handles location capture, Overpass API queries, place suggestions,
/// form validation, and saving visits to the repository.
class RecordVisitViewModel extends ChangeNotifier {
  /// Creates a new [RecordVisitViewModel].
  ///
  /// All dependencies are injected for testability:
  /// - [locationService]: Service for getting GPS location
  /// - [overpassClient]: Client for querying Overpass API
  /// - [visitRepository]: Repository for saving visits
  /// - [authNotifier]: Notifier for getting current user ID
  RecordVisitViewModel({
    required LocationService locationService,
    required OverpassClient overpassClient,
    required VisitRepository visitRepository,
    required AuthNotifier authNotifier,
  }) : _locationService = locationService,
       _overpassClient = overpassClient,
       _visitRepository = visitRepository,
       _authNotifier = authNotifier;

  final LocationService _locationService;
  final OverpassClient _overpassClient;
  final VisitRepository _visitRepository;
  final AuthNotifier _authNotifier;

  Position? _currentLocation;
  List<PlaceSuggestion> _suggestions = [];
  PlaceSuggestion? _selectedSuggestion;
  String _placeName = '';
  bool _isLoadingLocation = false;
  bool _isLoadingSuggestions = false;
  bool _isSaving = false;
  String? _error;
  bool _isPermissionDeniedForever = false;

  /// The current GPS location, or `null` if not available.
  Position? get currentLocation => _currentLocation;

  /// List of place suggestions from Overpass API.
  List<PlaceSuggestion> get suggestions => _suggestions;

  /// The currently selected place suggestion, or `null` if none selected.
  PlaceSuggestion? get selectedSuggestion => _selectedSuggestion;

  /// The manually entered place name.
  String get placeName => _placeName;

  /// Whether location is currently being fetched.
  bool get isLoadingLocation => _isLoadingLocation;

  /// Whether place suggestions are currently being fetched.
  bool get isLoadingSuggestions => _isLoadingSuggestions;

  /// Whether a visit is currently being saved.
  bool get isSaving => _isSaving;

  /// The current error message, or `null` if no error.
  String? get error => _error;

  /// Whether location permission is denied forever (requires opening app settings).
  bool get isPermissionDeniedForever => _isPermissionDeniedForever;

  /// Whether the form is valid and can be saved.
  ///
  /// Requires:
  /// - Place name is not empty
  /// - Current location is available
  bool get canSave {
    return _placeName.trim().isNotEmpty && _currentLocation != null;
  }

  /// Initializes the view model by getting current location and fetching
  /// place suggestions.
  ///
  /// This should be called when the screen is first opened.
  /// Handles errors gracefully and does not throw exceptions.
  Future<void> initialize() async {
    await refreshLocation();
  }

  /// Refreshes the current location and updates place suggestions.
  ///
  /// Checks location services, requests permission if needed, gets GPS location,
  /// and queries Overpass API for nearby places. Handles errors gracefully.
  Future<void> refreshLocation() async {
    _setError(null);
    _setLoadingLocation(true);
    _setPermissionDeniedForever(false);

    try {
      // Check if location services are enabled first
      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError(
          'Location services are disabled. Please enable location services in your device settings. You can still enter a place name manually.',
        );
        _setLoadingLocation(false);
        return;
      }

      // Check if permission is denied forever first
      final deniedForever = await _locationService.isPermissionDeniedForever();
      if (deniedForever) {
        _setPermissionDeniedForever(true);
        _setError(
          'Location permission was denied. Please enable it in app settings. You can still enter a place name manually.',
        );
        _setLoadingLocation(false);
        return;
      }

      // Check current permission status and request if needed
      final hasPermission = await _locationService.hasPermission();
      if (!hasPermission) {
        // Request permission - this will show the system permission dialog
        final granted = await _locationService.requestPermission();
        if (!granted) {
          // Check again if it's now denied forever
          final nowDeniedForever = await _locationService
              .isPermissionDeniedForever();
          if (nowDeniedForever) {
            _setPermissionDeniedForever(true);
            _setError(
              'Location permission was denied. Please enable it in app settings. You can still enter a place name manually.',
            );
          } else {
            _setError(
              'Location permission is required to get your current location. You can still enter a place name manually.',
            );
          }
          _setLoadingLocation(false);
          return;
        }
      }

      // Get current location
      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        _setError(
          'Location unavailable. You can still enter a place name manually.',
        );
        _setLoadingLocation(false);
        return;
      }

      _setCurrentLocation(position);
      _setLoadingLocation(false);

      // Fetch place suggestions
      await _fetchSuggestions(position.latitude, position.longitude);
    } on Exception catch (e) {
      AppLogger.error({
        'event': 'record_visit_refresh_location_error',
        'error': e,
      });
      _setError('Failed to get location: ${e.toString()}');
      _setLoadingLocation(false);
    }
  }

  /// Opens the app settings page where the user can grant location permission.
  ///
  /// This should be called when permission is denied forever.
  Future<void> openAppSettings() async {
    try {
      await _locationService.openAppSettings();
    } catch (e) {
      AppLogger.error({
        'event': 'record_visit_open_app_settings_error',
        'error': e,
      });
    }
  }

  /// Fetches place suggestions from Overpass API for the given coordinates.
  ///
  /// Handles errors gracefully and does not throw exceptions.
  Future<void> _fetchSuggestions(double latitude, double longitude) async {
    _setLoadingSuggestions(true);
    _setError(null);

    try {
      final suggestions = await _overpassClient.findNearbyPlaces(
        latitude,
        longitude,
        radiusMeters: 20,
      );

      _setSuggestions(suggestions);
      _setLoadingSuggestions(false);
    } on http.ClientException catch (e) {
      AppLogger.error({
        'event': 'record_visit_fetch_suggestions_network_error',
        'error': e,
        'latitude': latitude,
        'longitude': longitude,
      });
      _setError('Network error: Unable to fetch place suggestions.');
      _setLoadingSuggestions(false);
    } on OverpassException catch (e) {
      AppLogger.error({
        'event': 'record_visit_fetch_suggestions_overpass_error',
        'error': e,
        'latitude': latitude,
        'longitude': longitude,
      });
      _setError('Unable to fetch place suggestions: ${e.eventName}');
      _setLoadingSuggestions(false);
    } on Exception catch (e) {
      AppLogger.error({
        'event': 'record_visit_fetch_suggestions_error',
        'error': e,
        'latitude': latitude,
        'longitude': longitude,
      });
      _setError('Failed to fetch place suggestions: ${e.toString()}');
      _setLoadingSuggestions(false);
    }
  }

  /// Selects a place suggestion and updates the place name.
  ///
  /// When a suggestion is selected, the place name is automatically set
  /// to the suggestion's name.
  void selectSuggestion(PlaceSuggestion suggestion) {
    _selectedSuggestion = suggestion;
    _placeName = suggestion.name;
    notifyListeners();
  }

  /// Updates the manually entered place name.
  ///
  /// Clears the selected suggestion if the name doesn't match any suggestion.
  void updatePlaceName(String name) {
    _placeName = name;

    // Clear selected suggestion if name doesn't match
    if (_selectedSuggestion != null && _selectedSuggestion!.name != name) {
      _selectedSuggestion = null;
    }

    notifyListeners();
  }

  /// Saves the visit to the repository.
  ///
  /// Validates the form data, creates a Visit object, and saves it.
  /// Throws [VisitDataException] if validation fails or save fails.
  /// Throws [StateError] if user is not authenticated.
  Future<void> saveVisit() async {
    if (!canSave) {
      throw StateError('Cannot save: form is not valid');
    }

    final user = _authNotifier.user;
    if (user == null) {
      throw StateError('User is not authenticated');
    }

    _setSaving(true);
    _setError(null);

    try {
      final now = DateTime.now();
      final visit = _buildVisit(user.uid, now);

      await _visitRepository.createVisit(visit);

      AppLogger.info({
        'event': 'record_visit_saved',
        'user_id': user.uid,
        'place_name': visit.placeName,
      });

      _setSaving(false);
    } on VisitDataException catch (e) {
      AppLogger.error({
        'event': 'record_visit_save_error',
        'error': e,
        'user_id': user.uid,
      });
      _setError('Failed to save visit: ${e.displayMessage}');
      _setSaving(false);
      rethrow;
    } on Exception catch (e) {
      AppLogger.error({
        'event': 'record_visit_save_error',
        'error': e,
        'user_id': user.uid,
      });
      _setError('Failed to save visit: ${e.toString()}');
      _setSaving(false);
      throw VisitDataException(
        'firestore',
        'record_visit_save_error',
        userId: user.uid,
        innerError: e,
      );
    }
  }

  /// Builds a Visit object from the current form state.
  ///
  /// Converts Position to GeoLatLong, PlaceSuggestion to Visit fields,
  /// and sets timestamps.
  Visit _buildVisit(String userId, DateTime now) {
    // Convert Position to GeoLatLong
    GeoLatLong? gpsRecorded;
    if (_currentLocation != null) {
      gpsRecorded = GeoLatLong(
        lat: _currentLocation!.latitude,
        long: _currentLocation!.longitude,
      );
    }

    // Extract data from selected suggestion if available
    GeoLatLong? gpsKnown;
    LocationType? placeType;
    Address? placeAddress;

    if (_selectedSuggestion != null) {
      final suggestion = _selectedSuggestion!;

      // Convert suggestion coordinates to GeoLatLong
      gpsKnown = GeoLatLong(
        lat: suggestion.latitude,
        long: suggestion.longitude,
      );

      // Parse amenityType string (format: "key:value") to LocationType
      if (suggestion.amenityType != null) {
        final parts = suggestion.amenityType!.split(':');
        if (parts.length == 2) {
          placeType = LocationType(type: parts[0], subType: parts[1]);
        }
      }

      // Parse address from suggestion tags or use formatted address
      placeAddress = _parseAddress(suggestion);
    }

    return Visit(
      userId: userId,
      placeName: _placeName.trim(),
      placeAddress: placeAddress,
      gpsRecorded: gpsRecorded,
      gpsKnown: gpsKnown,
      placeType: placeType,
      addedAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Parses an Address from a PlaceSuggestion.
  ///
  /// Extracts address components from the suggestion's tags (addr:*),
  /// or creates a simple address from the formatted address string.
  Address? _parseAddress(PlaceSuggestion suggestion) {
    final tags = suggestion.tags;

    // Try to extract structured address from tags
    final nameNumber = tags['addr:housenumber'];
    final street = tags['addr:street'];
    final city = tags['addr:city'];
    final postcode = tags['addr:postcode'];

    // If we have at least one address component, create Address object
    if (nameNumber != null ||
        street != null ||
        city != null ||
        postcode != null) {
      return Address(
        nameNumber: nameNumber,
        street: street,
        city: city,
        postcode: postcode,
      );
    }

    // Fallback: if we have a formatted address string, store it in street
    if (suggestion.address != null && suggestion.address!.isNotEmpty) {
      return Address(street: suggestion.address);
    }

    return null;
  }

  /// Cancels the current operation and resets the form.
  ///
  /// This method can be called to discard changes and reset state.
  void cancel() {
    _placeName = '';
    _selectedSuggestion = null;
    _error = null;
    notifyListeners();
  }

  // Private setters that update state and notify listeners

  void _setCurrentLocation(Position? location) {
    _currentLocation = location;
    notifyListeners();
  }

  void _setSuggestions(List<PlaceSuggestion> suggestions) {
    _suggestions = suggestions;
    notifyListeners();
  }

  void _setLoadingLocation(bool loading) {
    _isLoadingLocation = loading;
    notifyListeners();
  }

  void _setLoadingSuggestions(bool loading) {
    _isLoadingSuggestions = loading;
    notifyListeners();
  }

  void _setSaving(bool saving) {
    _isSaving = saving;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _setPermissionDeniedForever(bool deniedForever) {
    _isPermissionDeniedForever = deniedForever;
    notifyListeners();
  }
}
