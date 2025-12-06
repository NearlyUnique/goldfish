import 'package:flutter/material.dart';
import 'package:goldfish/core/data/models/place_suggestion_model.dart';
import 'package:goldfish/features/visits/domain/view_models/record_visit_view_model.dart';

/// Widget for displaying place suggestions from Overpass API.
///
/// Shows a list of nearby places with their name, type, and address.
/// Allows users to select a suggestion, which updates the view model.
/// Handles loading, empty, and error states.
class PlaceSuggestionsList extends StatelessWidget {
  /// Creates a new [PlaceSuggestionsList].
  const PlaceSuggestionsList({
    super.key,
    required this.viewModel,
  });

  /// The view model that provides suggestions and handles selection.
  final RecordVisitViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        // Show loading state
        if (viewModel.isLoadingSuggestions) {
          return const _LoadingState();
        }

        // Show error state if there's an error and no suggestions
        if (viewModel.error != null && viewModel.suggestions.isEmpty) {
          return _ErrorState(message: viewModel.error!);
        }

        // Show empty state if no suggestions
        if (viewModel.suggestions.isEmpty) {
          return const _EmptyState();
        }

        // Show list of suggestions
        return _SuggestionsList(
          suggestions: viewModel.suggestions,
          selectedSuggestion: viewModel.selectedSuggestion,
          onSuggestionSelected: (suggestion) {
            viewModel.selectSuggestion(suggestion);
          },
        );
      },
    );
  }
}

/// Widget displaying a loading indicator.
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Finding nearby places...'),
          ],
        ),
      ),
    );
  }
}

/// Widget displaying an error message.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget displaying an empty state message.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_searching,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No nearby places found',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You can enter a place name manually below',
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
}

/// Widget displaying the list of place suggestions.
class _SuggestionsList extends StatelessWidget {
  const _SuggestionsList({
    required this.suggestions,
    required this.selectedSuggestion,
    required this.onSuggestionSelected,
  });

  final List<PlaceSuggestion> suggestions;
  final PlaceSuggestion? selectedSuggestion;
  final ValueChanged<PlaceSuggestion> onSuggestionSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Nearby Places',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: suggestions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            final isSelected = selectedSuggestion == suggestion;

            return _SuggestionCard(
              suggestion: suggestion,
              isSelected: isSelected,
              onTap: () => onSuggestionSelected(suggestion),
            );
          },
        ),
      ],
    );
  }
}

/// Widget displaying a single place suggestion card.
class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.isSelected,
    required this.onTap,
  });

  final PlaceSuggestion suggestion;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = isSelected
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;

    return Card(
      color: cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      suggestion.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                : null,
                          ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                ],
              ),
              if (suggestion.amenityType != null) ...[
                const SizedBox(height: 8),
                _AmenityTypeChip(
                  amenityType: suggestion.amenityType!,
                  isSelected: isSelected,
                ),
              ],
              if (suggestion.address != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: isSelected
                          ? colorScheme.onPrimaryContainer.withOpacity(0.7)
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        suggestion.address!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? colorScheme.onPrimaryContainer.withOpacity(0.7)
                                  : colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget displaying an amenity type as a chip.
class _AmenityTypeChip extends StatelessWidget {
  const _AmenityTypeChip({
    required this.amenityType,
    required this.isSelected,
  });

  final String amenityType;
  final bool isSelected;

  IconData _getIconForType(String type) {
    // Parse the type (format: "key:value")
    final parts = type.split(':');
    if (parts.length < 2) {
      return Icons.place;
    }

    final key = parts[0];
    final value = parts[1];

    // Map common amenity types to icons
    switch (key) {
      case 'amenity':
        switch (value) {
          case 'restaurant':
          case 'cafe':
          case 'fast_food':
            return Icons.restaurant;
          case 'pub':
          case 'bar':
            return Icons.local_bar;
          case 'hotel':
            return Icons.hotel;
          case 'hospital':
          case 'clinic':
            return Icons.local_hospital;
          case 'school':
          case 'university':
            return Icons.school;
          case 'pharmacy':
            return Icons.local_pharmacy;
          case 'bank':
            return Icons.account_balance;
          case 'fuel':
            return Icons.local_gas_station;
          case 'parking':
            return Icons.local_parking;
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
      case 'office':
        return Icons.business;
      default:
        return Icons.place;
    }
  }

  String _formatType(String type) {
    // Format "key:value" to "Value" or "Key: Value"
    final parts = type.split(':');
    if (parts.length < 2) {
      return type;
    }

    final key = parts[0];
    final value = parts[1];

    // Capitalize and replace underscores with spaces
    final formattedValue = value
        .split('_')
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1))
        .join(' ');

    // For common keys, just show the value
    if (key == 'amenity' || key == 'tourism' || key == 'shop') {
      return formattedValue;
    }

    // Otherwise show "Key: Value"
    final formattedKey = key[0].toUpperCase() + key.substring(1);
    return '$formattedKey: $formattedValue';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isSelected
        ? colorScheme.primary.withOpacity(0.2)
        : colorScheme.surfaceContainerHighest;
    final textColor = isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Chip(
      avatar: Icon(
        _getIconForType(amenityType),
        size: 18,
        color: textColor,
      ),
      label: Text(
        _formatType(amenityType),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
      ),
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

