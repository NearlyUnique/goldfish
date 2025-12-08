import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goldfish/core/theme/app_theme.dart';
import 'package:goldfish/features/map/presentation/widgets/osm_attribution.dart';

void main() {
  group('OsmAttribution', () {
    Widget createWidgetUnderTest({
      Alignment alignment = Alignment.bottomRight,
      bool showLink = true,
    }) {
      return MaterialApp(
        theme: lightTheme,
        darkTheme: darkTheme,
        home: Scaffold(
          body: Stack(
            children: [
              Container(color: Colors.blue),
              OsmAttribution(
                alignment: alignment,
                showLink: showLink,
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('displays attribution text', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(
        find.text('© OpenStreetMap contributors'),
        findsOneWidget,
      );
    });

    testWidgets('positions widget in bottom-right by default', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act
      final attributionFinder = find.byType(OsmAttribution);
      expect(attributionFinder, findsOneWidget);

      final attributionWidget = tester.widget<OsmAttribution>(
        attributionFinder,
      );

      // Assert
      expect(attributionWidget.alignment, equals(Alignment.bottomRight));
    });

    testWidgets('uses custom alignment when provided', (tester) async {
      // Arrange
      const customAlignment = Alignment.topLeft;
      await tester.pumpWidget(
        createWidgetUnderTest(alignment: customAlignment),
      );
      await tester.pumpAndSettle();

      // Act
      final attributionFinder = find.byType(OsmAttribution);
      final attributionWidget = tester.widget<OsmAttribution>(
        attributionFinder,
      );

      // Assert
      expect(attributionWidget.alignment, equals(customAlignment));
    });

    testWidgets('applies bodySmall text style', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act
      final textFinder = find.text('© OpenStreetMap contributors');
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);

      // Assert
      expect(textWidget.style?.fontSize, equals(12.0));
    });

    testWidgets('has semi-transparent background', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act
      final containerFinder = find.ancestor(
        of: find.text('© OpenStreetMap contributors'),
        matching: find.byType(Container),
      );
      expect(containerFinder, findsWidgets);

      final containerWidget = tester.widget<Container>(
        containerFinder.first,
      );

      // Assert
      expect(containerWidget.decoration, isA<BoxDecoration>());
      final decoration = containerWidget.decoration as BoxDecoration;
      expect(decoration.color, isNotNull);
    });

    testWidgets('has padding around text', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act
      final paddingFinder = find.ancestor(
        of: find.text('© OpenStreetMap contributors'),
        matching: find.byType(Padding),
      );
      expect(paddingFinder, findsWidgets);

      final paddingWidget = tester.widget<Padding>(paddingFinder.first);

      // Assert
      expect(paddingWidget.padding, isA<EdgeInsets>());
    });

    testWidgets('wraps text in InkWell when showLink is true', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest(showLink: true));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('does not wrap text in InkWell when showLink is false',
        (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest(showLink: false));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('has rounded corners', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act
      final containerFinder = find.ancestor(
        of: find.text('© OpenStreetMap contributors'),
        matching: find.byType(Container),
      );
      final containerWidget = tester.widget<Container>(
        containerFinder.first,
      );

      // Assert
      expect(containerWidget.decoration, isA<BoxDecoration>());
      final decoration = containerWidget.decoration as BoxDecoration;
      expect(decoration.borderRadius, isA<BorderRadius>());
    });

    testWidgets('adapts to dark theme', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.dark,
          home: Scaffold(
            body: Stack(
              children: [
                Container(color: Colors.blue),
                const OsmAttribution(),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('© OpenStreetMap contributors'),
        findsOneWidget,
      );
    });
  });
}

