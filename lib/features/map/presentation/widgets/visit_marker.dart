import 'package:flutter/material.dart';

/// Marker widget used to display visits on the map.
///
/// By default this renders a visit pin using the theme's primary color. When
/// [isCurrentLocation] is true it renders a distinct marker for the user's
/// current location using the tertiary color. An optional [onTap] callback can
/// be provided to surface a ripple and handle tap interactions.
class VisitMarker extends StatelessWidget {
  const VisitMarker({
    super.key,
    this.isCurrentLocation = false,
    this.onTap,
    this.semanticLabel,
  });

  /// Whether this marker represents the current location.
  final bool isCurrentLocation;

  /// Optional tap handler for the marker.
  final VoidCallback? onTap;

  /// Optional semantics label for accessibility.
  final String? semanticLabel;

  static const double _size = 32;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isCurrentLocation
        ? colorScheme.tertiary
        : colorScheme.primary;
    final foregroundColor = isCurrentLocation
        ? colorScheme.onTertiary
        : colorScheme.onPrimary;
    final icon = isCurrentLocation ? Icons.my_location : Icons.place;

    Widget marker = Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: foregroundColor,
        size: 18,
        semanticLabel: semanticLabel,
      ),
    );

    if (onTap != null) {
      marker = Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: marker,
        ),
      );
    }

    return Semantics(
      label: semanticLabel ?? _defaultLabel,
      button: onTap != null,
      child: marker,
    );
  }

  String get _defaultLabel =>
      isCurrentLocation ? 'Current location' : 'Visited place';
}

/// Convenience marker specifically for the user's current location.
class CurrentLocationMarker extends StatelessWidget {
  const CurrentLocationMarker({super.key, this.onTap, this.semanticLabel});

  /// Optional tap handler for the marker.
  final VoidCallback? onTap;

  /// Optional semantics label for accessibility.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return VisitMarker(
      isCurrentLocation: true,
      onTap: onTap,
      semanticLabel: semanticLabel ?? 'Current location',
    );
  }
}
