import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget that displays OpenStreetMap attribution as required by OSM licensing.
///
/// This widget displays the required attribution text "© OpenStreetMap
/// contributors" and optionally provides a link to the OSM copyright page.
/// It is designed to be positioned in the bottom-right corner of a map view
/// using a [Stack] and [Positioned] widget.
///
/// Example usage:
/// ```dart
/// Stack(
///   children: [
///     MapWidget(),
///     OsmAttribution(),
///   ],
/// )
/// ```
class OsmAttribution extends StatelessWidget {
  /// Creates a new [OsmAttribution] widget.
  ///
  /// The [alignment] parameter controls the position of the attribution.
  /// Defaults to [Alignment.bottomRight].
  ///
  /// The [showLink] parameter controls whether the attribution text is
  /// clickable and opens the OSM copyright page. Defaults to `true`.
  const OsmAttribution({
    super.key,
    this.alignment = Alignment.bottomRight,
    this.showLink = true,
  });

  /// The alignment of the attribution widget within its parent.
  ///
  /// Defaults to [Alignment.bottomRight] to position in the bottom-right
  /// corner of the map.
  final Alignment alignment;

  /// Whether to make the attribution text clickable to open the OSM copyright
  /// page.
  ///
  /// Defaults to `true`.
  final bool showLink;

  /// The URL to the OpenStreetMap copyright page.
  static const String _osmCopyrightUrl = 'https://www.openstreetmap.org/copyright';

  /// The attribution text as required by OSM licensing.
  static const String _attributionText = '© OpenStreetMap contributors';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(0.7),
    );

    final backgroundColor = theme.colorScheme.surface.withOpacity(0.8);

    Widget attributionContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        _attributionText,
        style: textStyle,
      ),
    );

    if (showLink) {
      attributionContent = InkWell(
        onTap: () => _openCopyrightPage(),
        borderRadius: BorderRadius.circular(4),
        child: attributionContent,
      );
    }

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: attributionContent,
      ),
    );
  }

  /// Opens the OpenStreetMap copyright page in the default browser.
  Future<void> _openCopyrightPage() async {
    final uri = Uri.parse(_osmCopyrightUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

