import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:goldfish/core/data/models/visit_model.dart';
import 'package:goldfish/core/logging/app_logger.dart';
import 'package:goldfish/features/map/domain/models/map_marker.dart';
import 'package:goldfish/features/map/presentation/widgets/osm_attribution.dart';
import 'package:goldfish/features/map/presentation/widgets/visit_marker.dart';

/// Displays an OpenStreetMap view with visit markers and the current location.
///
/// Handles loading, error, and empty states while keeping the map centred on the
/// user's location when available. Falls back to the centre of the provided
/// visits or a default location when no coordinates are available.
class MapViewWidget extends StatefulWidget {
  /// Creates a new [MapViewWidget].
  const MapViewWidget({
    super.key,
    this.currentLocation,
    required this.visits,
    this.onRetry,
    this.isLoading = false,
    this.errorMessage,
    this.tileProvider,
    this.tileUserAgent = _defaultUserAgent,
  });

  /// The user's current location. When null the map centres on visit markers or
  /// a fallback location.
  final GeoLatLong? currentLocation;

  /// The visits to render as markers.
  final List<Visit> visits;

  /// Optional callback to retry loading when an error occurs.
  final VoidCallback? onRetry;

  /// Whether the map data is currently loading.
  final bool isLoading;

  /// An optional error message to surface to the user.
  final String? errorMessage;

  /// Allows injecting a custom tile provider (e.g. a cached provider or a stub
  /// in tests).
  final TileProvider? tileProvider;

  /// User-Agent header sent with tile requests. Update the contact address to
  /// meet OSM usage guidance.
  final String tileUserAgent;

  static const double _defaultZoom = 15;
  static const LatLng _fallbackCentre = LatLng(51.5074, -0.1278);
  static const String _tileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  // The contact email should be updated to the team's preferred address.
  static const String _defaultUserAgent =
      'Goldfish/1.0.0 (contact: update-contact@example.com)';

  @override
  State<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends State<MapViewWidget> {
  late final MapController _mapController;
  GeoLatLong? _previousLocation;
  static const double _distanceThresholdMeters = 10.0;
  final Distance _distance = const Distance();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _previousLocation = widget.currentLocation;
  }

  @override
  void didUpdateWidget(MapViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleLocationUpdate(oldWidget.currentLocation, widget.currentLocation);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Handles location updates and re-centres the map if the user has moved
  /// more than 10 meters, preserving the current zoom and rotation.
  void _handleLocationUpdate(
    GeoLatLong? oldLocation,
    GeoLatLong? newLocation,
  ) {
    // Only process if we have a new location
    if (newLocation == null) {
      _previousLocation = null;
      return;
    }

    // If this is the first location, just store it
    if (_previousLocation == null) {
      _previousLocation = newLocation;
      return;
    }

    // Calculate distance between previous and new location
    final previousLatLng = _toLatLng(_previousLocation!);
    final newLatLng = _toLatLng(newLocation);
    final distanceMeters = _distance(previousLatLng, newLatLng);

    // If moved more than threshold, re-centre the map
    if (distanceMeters > _distanceThresholdMeters) {
      // Get current camera state to preserve zoom and rotation
      final currentCamera = _mapController.camera;
      // Move to new location preserving zoom
      _mapController.move(newLatLng, currentCamera.zoom);
      // Restore rotation to preserve it
      _mapController.rotate(currentCamera.rotation);
      _previousLocation = newLocation;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const _LoadingState();
    }

    final markers = MapMarker.fromVisits(widget.visits);
    final mapCentre = _resolveCentre(markers, widget.currentLocation);

    if (widget.currentLocation == null && markers.isEmpty) {
      if (widget.errorMessage != null) {
        return _ErrorState(
          message: widget.errorMessage!,
          onRetry: widget.onRetry,
        );
      }
      return _EmptyState(onRetry: widget.onRetry);
    }

    final markerWidgets = <Marker>[
      if (widget.currentLocation != null)
        _buildCurrentLocationMarker(widget.currentLocation!),
      ...markers.map(_buildVisitMarker),
    ];

    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapCentre,
              initialZoom: MapViewWidget._defaultZoom,
              minZoom: 3,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: MapViewWidget._tileUrl,
                tileProvider: widget.tileProvider ??
                    NetworkTileProvider(headers: _tileHeaders),
                errorTileCallback: (tile, error, stackTrace) {
                  AppLogger.error({
                    'event': 'map_tile_load_error',
                    'tile_coordinates':
                        'z:${tile.coordinates.z}, x:${tile.coordinates.x}, y:${tile.coordinates.y}',
                    'error': error.toString(),
                  });
                },
              ),
              if (markerWidgets.isNotEmpty)
                MarkerLayer(markers: markerWidgets),
            ],
          ),
        ),
        const OsmAttribution(),
        if (widget.errorMessage != null)
          _InlineError(
            message: widget.errorMessage!,
            onRetry: widget.onRetry,
          ),
      ],
    );
  }

  Map<String, String> get _tileHeaders =>
      {'User-Agent': widget.tileUserAgent};

  Marker _buildVisitMarker(MapMarker marker) {
    return Marker(
      key: ValueKey('visit-${marker.visitId}'),
      point: _toLatLng(marker.coordinates),
      width: 44,
      height: 44,
      child: VisitMarker(semanticLabel: marker.placeName),
    );
  }

  Marker _buildCurrentLocationMarker(GeoLatLong location) {
    return Marker(
      key: const ValueKey('current-location'),
      point: _toLatLng(location),
      width: 44,
      height: 44,
      child: const CurrentLocationMarker(),
    );
  }

  LatLng _resolveCentre(List<MapMarker> markers, GeoLatLong? location) {
    if (location != null) {
      return _toLatLng(location);
    }

    if (markers.isNotEmpty) {
      final latSum = markers.fold<double>(
        0,
        (total, marker) => total + marker.coordinates.lat,
      );
      final longSum = markers.fold<double>(
        0,
        (total, marker) => total + marker.coordinates.long,
      );
      return LatLng(latSum / markers.length, longSum / markers.length);
    }

    return MapViewWidget._fallbackCentre;
  }

  LatLng _toLatLng(GeoLatLong coordinates) =>
      LatLng(coordinates.lat, coordinates.long);
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Loading map...'),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 48),
            const SizedBox(height: 12),
            const Text('No visits to display on map.'),
            const SizedBox(height: 12),
            if (onRetry != null)
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isSettingsAction = message.contains('settings');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
            if (onRetry != null)
              ElevatedButton(
                onPressed: onRetry,
                child: Text(isSettingsAction ? 'Open Settings' : 'Retry'),
              ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSettingsAction = message.contains('settings');
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  if (onRetry != null) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: onRetry,
                      child: Text(isSettingsAction ? 'Open Settings' : 'Retry'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
