import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:goldfish/core/api/http_client.dart';
import 'package:goldfish/core/api/overpass_client.dart';
import 'package:goldfish/core/auth/auth_notifier.dart';
import 'package:goldfish/core/data/models/place_suggestion_model.dart';
import 'package:goldfish/core/data/repositories/visit_repository.dart';
import 'package:goldfish/core/location/location_service.dart';
import 'package:goldfish/features/visits/domain/view_models/record_visit_view_model.dart';
import 'package:goldfish/features/visits/presentation/widgets/place_suggestions_list.dart';

/// Screen for recording a new visit to a location.
///
/// Allows users to:
/// - Capture GPS location automatically
/// - View place suggestions from Overpass API
/// - Select a place from suggestions or enter manually
/// - Save the visit to Firestore
class RecordVisitScreen extends StatefulWidget {
  /// Creates a new [RecordVisitScreen].
  const RecordVisitScreen({
    super.key,
    required this.authNotifier,
  });

  /// The authentication notifier for getting the current user.
  final AuthNotifier authNotifier;

  @override
  State<RecordVisitScreen> createState() => _RecordVisitScreenState();
}

class _RecordVisitScreenState extends State<RecordVisitScreen> {
  late final RecordVisitViewModel _viewModel;
  final _placeNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _viewModel = _createViewModel();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _placeNameController.dispose();
    super.dispose();
  }

  /// Creates a [RecordVisitViewModel] with all required dependencies.
  RecordVisitViewModel _createViewModel() {
    final locationService = GeolocatorLocationService();
    final httpClient = HttpPackageClient();
    final overpassClient = OverpassClient(httpClient: httpClient);
    final visitRepository = VisitRepository();

    return RecordVisitViewModel(
      locationService: locationService,
      overpassClient: overpassClient,
      visitRepository: visitRepository,
      authNotifier: widget.authNotifier,
    );
  }

  /// Handles ViewModel state changes, updating the UI accordingly.
  void _onViewModelChanged() {
    // Update text field if place name changed (e.g., from suggestion selection)
    if (_placeNameController.text != _viewModel.placeName) {
      _placeNameController.text = _viewModel.placeName;
    }
  }

  /// Handles the save button tap.
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_viewModel.canSave) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a place name and ensure location is available.'),
        ),
      );
      return;
    }

    try {
      await _viewModel.saveVisit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visit recorded successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save visit: ${e.toString()}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Handles the cancel button tap.
  void _handleCancel() {
    _viewModel.cancel();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Visit'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _handleCancel,
          tooltip: 'Cancel',
        ),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Location status section
                      _LocationStatusSection(viewModel: _viewModel),
                      const SizedBox(height: 24),

                      // Place suggestions list (if location available)
                      if (_viewModel.currentLocation != null) ...[
                        PlaceSuggestionsList(viewModel: _viewModel),
                        const SizedBox(height: 24),
                        // Divider with "OR" text
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Manual entry section
                      _ManualEntrySection(
                        viewModel: _viewModel,
                        controller: _placeNameController,
                      ),
                      const SizedBox(height: 24),

                      // Selected suggestion details (if any)
                      if (_viewModel.selectedSuggestion != null) ...[
                        _SelectedSuggestionDetails(
                          suggestion: _viewModel.selectedSuggestion!,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),

              // Loading overlay during save
              if (_viewModel.isSaving)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _handleCancel,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _viewModel.canSave && !_viewModel.isSaving
                          ? _handleSave
                          : null,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Widget displaying the current location status.
class _LocationStatusSection extends StatelessWidget {
  const _LocationStatusSection({required this.viewModel});

  final RecordVisitViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoadingLocation) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Getting your location...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (viewModel.currentLocation != null) {
      final location = viewModel.currentLocation!;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Location',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // Location unavailable
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_off,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location unavailable',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (viewModel.error != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          viewModel.error!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (viewModel.isPermissionDeniedForever) ...[
                  FilledButton.icon(
                    onPressed: () async {
                      await viewModel.openAppSettings();
                      // Refresh location after user returns from settings
                      // (they might have granted permission)
                      await viewModel.refreshLocation();
                    },
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('Open Settings'),
                  ),
                  const SizedBox(width: 8),
                ],
                TextButton(
                  onPressed: viewModel.refreshLocation,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for manual place name entry.
class _ManualEntrySection extends StatelessWidget {
  const _ManualEntrySection({
    required this.viewModel,
    required this.controller,
  });

  final RecordVisitViewModel viewModel;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Place Name',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter place name',
            prefixIcon: Icon(Icons.place),
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (value) {
            viewModel.updatePlaceName(value);
          },
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a place name';
            }
            return null;
          },
        ),
      ],
    );
  }
}

/// Widget displaying details of the selected suggestion.
class _SelectedSuggestionDetails extends StatelessWidget {
  const _SelectedSuggestionDetails({required this.suggestion});

  final PlaceSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Selected Place',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ],
            ),
            if (suggestion.amenityType != null) ...[
              const SizedBox(height: 8),
              Text(
                'Type: ${suggestion.amenityType}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ],
            if (suggestion.address != null) ...[
              const SizedBox(height: 4),
              Text(
                'Address: ${suggestion.address}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

