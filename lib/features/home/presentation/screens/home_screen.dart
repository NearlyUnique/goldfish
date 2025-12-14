import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:goldfish/core/auth/auth_notifier.dart';
import 'package:goldfish/core/data/models/visit_model.dart';
import 'package:goldfish/core/data/repositories/visit_repository.dart';
import 'package:goldfish/core/data/visit_exceptions.dart';
import 'package:goldfish/core/location/location_service.dart';
import 'package:goldfish/core/logging/app_logger.dart';
import 'package:goldfish/features/map/presentation/widgets/map_view_widget.dart';
import 'package:url_launcher/url_launcher.dart';

/// View mode for the home screen.
enum ViewMode {
  /// List view showing visits as a scrollable list.
  list,

  /// Map view showing visits as markers on a map.
  map,
}

/// Home screen displaying authenticated user's visits.
///
/// Shows a list of recorded visits with pull-to-refresh functionality.
/// Supports toggling between list and map views.
class HomeScreen extends StatefulWidget {
  /// Creates a new [HomeScreen].
  const HomeScreen({
    super.key,
    required this.authNotifier,
    VisitRepository? visitRepository,
    LocationService? locationService,
    TileProvider? tileProvider,
  }) : _visitRepository = visitRepository,
       _locationService = locationService,
       _tileProvider = tileProvider;

  /// The authentication notifier for managing auth state.
  final AuthNotifier authNotifier;

  /// The visit repository for fetching visits.
  ///
  /// If not provided, creates a default [VisitRepository] instance.
  final VisitRepository? _visitRepository;

  /// The location service for getting current location.
  ///
  /// If not provided, creates a default [GeolocatorLocationService] instance.
  final LocationService? _locationService;

  /// The tile provider for the map view.
  ///
  /// If not provided, uses the default network tile provider.
  /// Primarily used for testing to avoid network requests.
  final TileProvider? _tileProvider;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final VisitRepository _visitRepository;
  late final LocationService _locationService;
  List<Visit> _visits = [];
  bool _isLoading = false;
  String? _error;
  ViewMode _viewMode = ViewMode.list;
  GeoLatLong? _currentLocation;
  bool _isLoadingLocation = false;
  String? _locationError;
  StreamSubscription<Position>? _locationStreamSubscription;
  Timer? _locationUpdateTimer;

  @override
  void initState() {
    super.initState();
    _visitRepository =
        widget._visitRepository ??
        VisitRepository(firestore: FirebaseFirestore.instance);
    _locationService = widget._locationService ?? GeolocatorLocationService();
    // Defer loading until after the first frame to avoid blocking main thread
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVisits();
    });
  }

  @override
  void dispose() {
    _stopLocationTracking();
    super.dispose();
  }

  Future<void> _loadVisits() async {
    final user = widget.authNotifier.user;
    if (user == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final visits = await _visitRepository.getUserVisits(user.uid);
      if (mounted) {
        setState(() {
          _visits = visits;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error({
        'event': 'home_load_visits_error',
        'user_id': user.uid,
        'error': e,
      });
      if (mounted) {
        setState(() {
          _error = e is VisitDataException
              ? e.displayMessage
              : 'Failed to load visits. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _handleViewModeChange(Set<ViewMode> selection) {
    final mode = selection.firstOrNull;
    if (mode == null || mode == _viewMode) {
      return;
    }

    setState(() {
      _viewMode = mode;
    });

    // Start/stop location tracking based on view mode
    if (mode == ViewMode.map) {
      _startLocationTracking();
    } else {
      _stopLocationTracking();
    }
  }

  Future<void> _handleOpenSettings() async {
    await _locationService.openAppSettings();
  }

  /// Starts continuous location tracking for the map view.
  ///
  /// Updates location when the device moves 10 meters or every 30 seconds,
  /// whichever comes first. Only tracks when map view is active.
  Future<void> _startLocationTracking() async {
    // Stop any existing tracking
    _stopLocationTracking();

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      // Check if location services are enabled first
      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _locationError =
                'Please enable location services in device settings.';
          });
        }
        return;
      }

      // Check if we already have permission
      final hasPermission = await _locationService.hasPermission();
      if (!hasPermission) {
        // Request permission
        final granted = await _locationService.requestPermission();
        if (!granted) {
          final deniedForever = await _locationService
              .isPermissionDeniedForever();
          if (mounted) {
            setState(() {
              _isLoadingLocation = false;
              _locationError = deniedForever
                  ? 'Location permission required. Tap to enable in settings.'
                  : 'Location permission is required to show your current location on the map.';
            });
          }
          return;
        }
      }

      // Get initial location
      final initialPosition = await _locationService.getCurrentLocation();
      if (mounted && initialPosition != null) {
        setState(() {
          _currentLocation = GeoLatLong(
            lat: initialPosition.latitude,
            long: initialPosition.longitude,
          );
          _isLoadingLocation = false;
          _locationError = null;
        });
      } else if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _locationError =
              'Unable to get current location. Showing visited places.';
        });
      }

      // Start listening to location stream (updates on 10m movement)
      final stream = _locationService.getPositionStream();
      if (stream != null && mounted) {
        _locationStreamSubscription = stream.listen(
          (position) {
            if (mounted) {
              setState(() {
                _currentLocation = GeoLatLong(
                  lat: position.latitude,
                  long: position.longitude,
                );
                _locationError = null;
              });
            }
          },
          onError: (error) {
            AppLogger.error({
              'event': 'home_location_stream_error',
              'error': error,
            });
            if (mounted) {
              setState(() {
                _locationError =
                    'Location tracking error. Showing last known location.';
              });
            }
          },
        );
      }

      // Start periodic timer for 30-second fallback updates
      if (mounted) {
        _locationUpdateTimer = Timer.periodic(const Duration(seconds: 30), (
          _,
        ) async {
          if (!mounted || _viewMode != ViewMode.map) {
            return;
          }

          try {
            final position = await _locationService.getCurrentLocation();
            if (mounted && position != null) {
              setState(() {
                _currentLocation = GeoLatLong(
                  lat: position.latitude,
                  long: position.longitude,
                );
                _locationError = null;
              });
            }
          } catch (e) {
            AppLogger.error({
              'event': 'home_location_timer_update_error',
              'error': e,
            });
            // Don't update error state on timer failures - stream might still work
          }
        });
      }
    } catch (e) {
      AppLogger.error({
        'event': 'home_start_location_tracking_error',
        'error': e,
      });
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _locationError =
              'Unable to start location tracking. Showing visited places.';
        });
      }
    }
  }

  /// Stops continuous location tracking.
  ///
  /// Cancels the location stream subscription and periodic timer.
  void _stopLocationTracking() {
    _locationStreamSubscription?.cancel();
    _locationStreamSubscription = null;
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.authNotifier.signOut();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    // If less than 1 day ago, show relative time
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      }
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    }

    // If less than 7 days ago, show days
    if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    }

    // Otherwise, show formatted date (e.g., "Jan 15, 2024")
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildVisitItem(Visit visit) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        title: Text(
          visit.placeName,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (visit.placeType != null) ...[
              const SizedBox(height: 8),
              _AmenityTypeChip(
                type: visit.placeType!.type,
                subType: visit.placeType!.subType,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _formatDate(visit.addedAt),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        onLongPress: () => _showVisitContextMenu(context, visit),
      ),
    );
  }

  /// Shows a context menu for a visit item with actions.
  void _showVisitContextMenu(BuildContext context, Visit visit) {
    final location = visit.gpsKnown ?? visit.gpsRecorded;

    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy to Clipboard'),
                onTap: () {
                  Navigator.of(context).pop();
                  _copyVisitToClipboard(context, visit);
                },
              ),
              if (location != null)
                ListTile(
                  leading: const Icon(Icons.map),
                  title: const Text('Open in Maps'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _openLocationInMaps(location, visit.placeName);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  /// Copies the visit's place name and address to the clipboard.
  void _copyVisitToClipboard(BuildContext context, Visit visit) {
    final buffer = StringBuffer();
    buffer.writeln(visit.placeName);
    if (visit.placeAddress != null) {
      buffer.write(visit.placeAddress!.toFormattedString());
    }
    final text = buffer.toString();

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Opens the given location in the default maps application.
  ///
  /// On Android, tries Google Maps URL first (most reliable), then falls back to geo: URI.
  /// On iOS, uses geo: URI which opens Apple Maps or user's preferred map app.
  Future<void> _openLocationInMaps(
    GeoLatLong location,
    String placeName,
  ) async {
    try {
      // Try Google Maps URL first (works reliably on Android and opens in app if installed)
      final googleMapsUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${location.lat},${location.long}',
      );

      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
        return;
      }

      // Fallback to simple geo: URI scheme (works on both Android and iOS)
      // Use simpler format without query parameters for better compatibility
      final geoUri = Uri.parse('geo:${location.lat},${location.long}');

      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        return;
      }

      // If both fail, show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open maps application')),
        );
      }
    } catch (e) {
      AppLogger.error({
        'event': 'home_open_maps_error',
        'error': e,
        'location': location.toString(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open maps application')),
        );
      }
    }
  }

  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<ViewMode>(
        segments: const [
          ButtonSegment<ViewMode>(
            value: ViewMode.list,
            icon: Icon(Icons.list),
            label: Text('List'),
          ),
          ButtonSegment<ViewMode>(
            value: ViewMode.map,
            icon: Icon(Icons.map),
            label: Text('Map'),
          ),
        ],
        selected: {_viewMode},
        onSelectionChanged: _handleViewModeChange,
      ),
    );
  }

  Widget _buildBody() {
    if (_viewMode == ViewMode.map) {
      return MapViewWidget(
        currentLocation: _currentLocation,
        visits: _visits,
        isLoading: _isLoadingLocation,
        errorMessage: _locationError,
        onRetry: _locationError != null && _locationError!.contains('settings')
            ? _handleOpenSettings
            : _startLocationTracking,
        tileProvider: widget._tileProvider,
      );
    }

    // List view (existing logic)
    if (_isLoading && _visits.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _visits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadVisits,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_visits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.place_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Nothing to remember',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the + button to record your first visit',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVisits,
      child: ListView.builder(
        itemCount: _visits.length,
        itemBuilder: (context, index) => _buildVisitItem(_visits[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goldfish'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleSignOut(context),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildViewToggle(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final bool? result = await context.push('/record-visit');
          // Refresh visits if a visit was saved (result is true)
          if (result ?? false) {
            _loadVisits();
          }
        },
        tooltip: 'Record Visit',
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Widget displaying an amenity type as a chip.
class _AmenityTypeChip extends StatelessWidget {
  const _AmenityTypeChip({required this.type, required this.subType});

  final String type;
  final String subType;

  IconData _getIconForType() {
    switch (type) {
      case 'amenity':
        switch (subType) {
          case 'pub':
          case 'bar':
            return Icons.local_bar;
          case 'restaurant':
          case 'cafe':
            return Icons.restaurant;
          case 'hotel':
            return Icons.hotel;
          case 'pharmacy':
            return Icons.local_pharmacy;
          case 'hospital':
            return Icons.local_hospital;
          case 'school':
            return Icons.school;
          default:
            return Icons.place;
        }
      case 'tourism':
        return Icons.camera_alt;
      case 'shop':
        return Icons.shopping_bag;
      case 'leisure':
        return Icons.sports_soccer;
      case 'historic':
        return Icons.museum;
      default:
        return Icons.place;
    }
  }

  String _formatType() {
    // Format "key:value" to "Value" or "Key: Value"
    final formattedValue = subType
        .split('_')
        .map(
          (word) =>
              word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');

    // For common keys, just show the value
    if (type == 'amenity' || type == 'tourism' || type == 'shop') {
      return formattedValue;
    }

    // Otherwise show "Key: Value"
    final formattedKey = type[0].toUpperCase() + type.substring(1);
    return '$formattedKey: $formattedValue';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Chip(
      avatar: Icon(
        _getIconForType(),
        size: 18,
        color: colorScheme.onSurfaceVariant,
      ),
      label: Text(
        _formatType(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
