import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldfish/core/theme/app_theme.dart';
import 'package:goldfish/features/map/presentation/widgets/visit_marker.dart';

void main() {
  Widget createWidgetUnderTest({
    bool isCurrentLocation = false,
    VoidCallback? onTap,
    String? semanticLabel,
  }) {
    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      home: Scaffold(
        body: Center(
          child: VisitMarker(
            isCurrentLocation: isCurrentLocation,
            onTap: onTap,
            semanticLabel: semanticLabel,
          ),
        ),
      ),
    );
  }

  group('VisitMarker', () {
    testWidgets('renders visit icon with primary colors', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(Icons.place));
      final container = _findMarkerContainer(tester);
      final decoration = container.decoration as BoxDecoration;

      expect(icon.color, lightTheme.colorScheme.onPrimary);
      expect(decoration.color, lightTheme.colorScheme.primary);
    });

    testWidgets('renders current location icon with tertiary colors', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(isCurrentLocation: true));
      await tester.pumpAndSettle();

      final icon = tester.widget<Icon>(find.byIcon(Icons.my_location));
      final container = _findMarkerContainer(tester);
      final decoration = container.decoration as BoxDecoration;

      expect(icon.color, lightTheme.colorScheme.onTertiary);
      expect(decoration.color, lightTheme.colorScheme.tertiary);
    });

    testWidgets('wraps with InkWell when onTap is provided', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(onTap: () {}));
      await tester.pumpAndSettle();

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('does not wrap with InkWell when onTap is null', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('invokes onTap callback when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        createWidgetUnderTest(
          onTap: () {
            tapped = true;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('applies default semantics label', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(VisitMarker),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Semantics &&
                    widget.properties.label != null &&
                    widget.properties.label == 'Visited place',
              ),
            )
            .first,
      );

      expect(semantics.properties.label, 'Visited place');
      expect(semantics.properties.button, isFalse);
    });

    testWidgets('uses provided semantics label and button flag', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(onTap: () {}, semanticLabel: 'Custom label'),
      );
      await tester.pumpAndSettle();

      final semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(VisitMarker),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Semantics &&
                    widget.properties.label != null &&
                    widget.properties.label == 'Custom label',
              ),
            )
            .first,
      );

      expect(semantics.properties.label, 'Custom label');
      expect(semantics.properties.button, isTrue);
    });
  });
}

Container _findMarkerContainer(WidgetTester tester) {
  final containerFinder = find.descendant(
    of: find.byType(VisitMarker),
    matching: find.byWidgetPredicate(
      (widget) => widget is Container && widget.decoration is BoxDecoration,
    ),
  );

  return tester.widget<Container>(containerFinder.first);
}
