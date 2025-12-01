import 'package:flutter_test/flutter_test.dart';
import 'package:goldfish/core/data/models/place_suggestion_model.dart';

void main() {
  group('PlaceSuggestion', () {
    test('creates instance with required fields', () {
      const suggestion = PlaceSuggestion(
        name: 'Test Place',
        latitude: 52.1993,
        longitude: 0.1390,
        tags: {},
      );
      expect(suggestion.name, 'Test Place');
      expect(suggestion.latitude, 52.1993);
      expect(suggestion.longitude, 0.1390);
      expect(suggestion.amenityType, isNull);
      expect(suggestion.address, isNull);
    });

    test('creates instance with all fields', () {
      const suggestion = PlaceSuggestion(
        name: 'Test Pub',
        amenityType: 'amenity:pub',
        latitude: 52.1993,
        longitude: 0.1390,
        address: '123 Main St, Cambridge',
        tags: {'amenity': 'pub', 'name': 'Test Pub'},
      );
      expect(suggestion.name, 'Test Pub');
      expect(suggestion.amenityType, 'amenity:pub');
      expect(suggestion.address, '123 Main St, Cambridge');
      expect(suggestion.tags['amenity'], 'pub');
    });

    group('fromOverpassElement', () {
      test('parses node element with name and coordinates', () {
        final element = {
          'type': 'node',
          'id': 123456,
          'lat': 52.1993,
          'lon': 0.1390,
          'tags': {'name': 'The Eagle', 'amenity': 'pub'},
        };

        final suggestion = PlaceSuggestion.fromOverpassElement(element);

        expect(suggestion.name, 'The Eagle');
        expect(suggestion.amenityType, 'amenity:pub');
        expect(suggestion.latitude, 52.1993);
        expect(suggestion.longitude, 0.1390);
        expect(suggestion.tags['name'], 'The Eagle');
        expect(suggestion.tags['amenity'], 'pub');
      });

      test('parses way element with center coordinates', () {
        final element = {
          'type': 'way',
          'id': 789012,
          'center': {'lat': 52.2050, 'lon': 0.1200},
          'tags': {'name': 'Cambridge Market', 'shop': 'market'},
        };

        final suggestion = PlaceSuggestion.fromOverpassElement(element);

        expect(suggestion.name, 'Cambridge Market');
        expect(suggestion.amenityType, 'shop:market');
        expect(suggestion.latitude, 52.2050);
        expect(suggestion.longitude, 0.1200);
      });

      test('parses relation element with center coordinates', () {
        final element = {
          'type': 'relation',
          'id': 345678,
          'center': {'lat': 52.2100, 'lon': 0.1100},
          'tags': {'name': 'King\'s College', 'tourism': 'attraction'},
        };

        final suggestion = PlaceSuggestion.fromOverpassElement(element);

        expect(suggestion.name, 'King\'s College');
        expect(suggestion.amenityType, 'tourism:attraction');
        expect(suggestion.latitude, 52.2100);
        expect(suggestion.longitude, 0.1100);
      });

      test('extracts address from addr:* tags', () {
        final element = {
          'type': 'node',
          'id': 123456,
          'lat': 52.1993,
          'lon': 0.1390,
          'tags': {
            'name': 'The Eagle',
            'amenity': 'pub',
            'addr:housenumber': '8',
            'addr:street': 'Benet Street',
            'addr:city': 'Cambridge',
            'addr:postcode': 'CB2 3QN',
          },
        };

        final suggestion = PlaceSuggestion.fromOverpassElement(element);

        expect(suggestion.address, '8, Benet Street, Cambridge, CB2 3QN');
      });

      test('handles partial address information', () {
        final element = {
          'type': 'node',
          'id': 123456,
          'lat': 52.1993,
          'lon': 0.1390,
          'tags': {
            'name': 'The Eagle',
            'addr:street': 'Benet Street',
            'addr:city': 'Cambridge',
          },
        };

        final suggestion = PlaceSuggestion.fromOverpassElement(element);

        expect(suggestion.address, 'Benet Street, Cambridge');
      });

      test('uses name:en as fallback when name not available', () {
        final element = {
          'type': 'node',
          'id': 123456,
          'lat': 52.1993,
          'lon': 0.1390,
          'tags': {'name:en': 'The Eagle Pub', 'amenity': 'pub'},
        };

        final suggestion = PlaceSuggestion.fromOverpassElement(element);

        expect(suggestion.name, 'The Eagle Pub');
      });

      test('uses "Unnamed Place" when no name found', () {
        final element = {
          'type': 'node',
          'id': 123456,
          'lat': 52.1993,
          'lon': 0.1390,
          'tags': {'amenity': 'pub'},
        };

        final suggestion = PlaceSuggestion.fromOverpassElement(element);

        expect(suggestion.name, 'Unnamed Place');
      });

      test('extracts different amenity types', () {
        final testCases = [
          {'amenity': 'restaurant', 'expected': 'amenity:restaurant'},
          {'tourism': 'hotel', 'expected': 'tourism:hotel'},
          {'shop': 'supermarket', 'expected': 'shop:supermarket'},
          {'leisure': 'park', 'expected': 'leisure:park'},
          {'historic': 'monument', 'expected': 'historic:monument'},
          {'craft': 'bakery', 'expected': 'craft:bakery'},
          {'office': 'company', 'expected': 'office:company'},
          {
            'public_transport': 'station',
            'expected': 'public_transport:station',
          },
        ];

        for (final testCase in testCases) {
          final tagKey = testCase.keys.first;
          final tagValue = testCase[tagKey] as String;
          final expected = testCase['expected'] as String;

          final element = {
            'type': 'node',
            'id': 123456,
            'lat': 52.1993,
            'lon': 0.1390,
            'tags': {'name': 'Test Place', tagKey: tagValue},
          };

          final suggestion = PlaceSuggestion.fromOverpassElement(element);
          expect(
            suggestion.amenityType,
            expected,
            reason: 'Failed for $tagKey',
          );
        }
      });

      test('returns null amenityType when no type tags found', () {
        final element = {
          'type': 'node',
          'id': 123456,
          'lat': 52.1993,
          'lon': 0.1390,
          'tags': {'name': 'Test Place'},
        };

        final suggestion = PlaceSuggestion.fromOverpassElement(element);

        expect(suggestion.amenityType, isNull);
      });

      test('handles empty tags map', () {
        final element = {
          'type': 'node',
          'id': 123456,
          'lat': 52.1993,
          'lon': 0.1390,
          'tags': <String, dynamic>{},
        };

        final suggestion = PlaceSuggestion.fromOverpassElement(element);

        expect(suggestion.name, 'Unnamed Place');
        expect(suggestion.amenityType, isNull);
        expect(suggestion.address, isNull);
        expect(suggestion.tags, isEmpty);
      });

      test('handles missing tags field', () {
        final element = {
          'type': 'node',
          'id': 123456,
          'lat': 52.1993,
          'lon': 0.1390,
        };

        final suggestion = PlaceSuggestion.fromOverpassElement(element);

        expect(suggestion.name, 'Unnamed Place');
        expect(suggestion.tags, isEmpty);
      });

      test('throws error for way without center or geometry', () {
        final element = {
          'type': 'way',
          'id': 789012,
          'tags': {'name': 'Test Way'},
        };

        expect(
          () => PlaceSuggestion.fromOverpassElement(element),
          throwsArgumentError,
        );
      });

      test('throws error for unknown element type', () {
        final element = {
          'type': 'unknown',
          'id': 123456,
          'tags': {'name': 'Test'},
        };

        expect(
          () => PlaceSuggestion.fromOverpassElement(element),
          throwsArgumentError,
        );
      });
    });

    group('fromOverpassResponse', () {
      test('parses response with multiple elements', () {
        final response = {
          'elements': [
            {
              'type': 'node',
              'id': 1,
              'lat': 52.1993,
              'lon': 0.1390,
              'tags': {'name': 'Place 1', 'amenity': 'pub'},
            },
            {
              'type': 'node',
              'id': 2,
              'lat': 52.2000,
              'lon': 0.1400,
              'tags': {'name': 'Place 2', 'shop': 'bakery'},
            },
          ],
        };

        final suggestions = PlaceSuggestion.fromOverpassResponse(response);

        expect(suggestions, hasLength(2));
        expect(suggestions[0].name, 'Place 1');
        expect(suggestions[1].name, 'Place 2');
      });

      test('returns empty list for response without elements', () {
        final response = <String, dynamic>{};

        final suggestions = PlaceSuggestion.fromOverpassResponse(response);

        expect(suggestions, isEmpty);
      });

      test('filters out invalid elements', () {
        final response = {
          'elements': [
            {
              'type': 'node',
              'id': 1,
              'lat': 52.1993,
              'lon': 0.1390,
              'tags': {'name': 'Valid Place'},
            },
            {
              'type': 'unknown',
              'id': 2,
              'tags': {'name': 'Invalid Place'},
            },
            {
              'type': 'node',
              'id': 3,
              'lat': 52.2000,
              'lon': 0.1400,
              'tags': {'name': 'Another Valid Place'},
            },
          ],
        };

        final suggestions = PlaceSuggestion.fromOverpassResponse(response);

        expect(suggestions, hasLength(2));
        expect(suggestions[0].name, 'Valid Place');
        expect(suggestions[1].name, 'Another Valid Place');
      });
    });

    group('copyWith', () {
      test('creates new instance with updated fields', () {
        const original = PlaceSuggestion(
          name: 'Original Name',
          latitude: 52.1993,
          longitude: 0.1390,
          tags: {'key': 'value'},
        );

        final updated = original.copyWith(
          name: 'Updated Name',
          amenityType: 'amenity:pub',
        );

        expect(updated.name, 'Updated Name');
        expect(updated.amenityType, 'amenity:pub');
        expect(updated.latitude, 52.1993); // Unchanged
        expect(updated.longitude, 0.1390); // Unchanged
      });

      test('preserves original values when null passed to copyWith', () {
        const original = PlaceSuggestion(
          name: 'Original Name',
          amenityType: 'amenity:pub',
          latitude: 52.1993,
          longitude: 0.1390,
          address: '123 Main St',
          tags: {},
        );

        // In Dart, copyWith with null preserves original values
        // (can't distinguish between "not provided" and "explicitly null")
        final updated = original.copyWith(amenityType: null, address: null);

        expect(updated.amenityType, 'amenity:pub'); // Preserved
        expect(updated.address, '123 Main St'); // Preserved
        expect(updated.name, 'Original Name'); // Unchanged
      });
    });

    group('equality', () {
      test('two instances with same values are equal', () {
        const suggestion1 = PlaceSuggestion(
          name: 'Test Place',
          amenityType: 'amenity:pub',
          latitude: 52.1993,
          longitude: 0.1390,
          address: '123 Main St',
          tags: {'key': 'value'},
        );

        const suggestion2 = PlaceSuggestion(
          name: 'Test Place',
          amenityType: 'amenity:pub',
          latitude: 52.1993,
          longitude: 0.1390,
          address: '123 Main St',
          tags: {'key': 'value'},
        );

        expect(suggestion1, suggestion2);
        expect(suggestion1.hashCode, suggestion2.hashCode);
      });

      test('two instances with different values are not equal', () {
        const suggestion1 = PlaceSuggestion(
          name: 'Test Place',
          latitude: 52.1993,
          longitude: 0.1390,
          tags: {},
        );

        const suggestion2 = PlaceSuggestion(
          name: 'Different Place',
          latitude: 52.1993,
          longitude: 0.1390,
          tags: {},
        );

        expect(suggestion1, isNot(suggestion2));
      });
    });

    group('toString', () {
      test('returns formatted string representation', () {
        const suggestion = PlaceSuggestion(
          name: 'Test Place',
          amenityType: 'amenity:pub',
          latitude: 52.1993,
          longitude: 0.1390,
          tags: {},
        );

        final str = suggestion.toString();

        expect(str, contains('PlaceSuggestion'));
        expect(str, contains('Test Place'));
        expect(str, contains('amenity:pub'));
        expect(str, contains('52.1993'));
        expect(str, contains('0.139')); // May be formatted as 0.139 or 0.1390
      });
    });
  });
}
