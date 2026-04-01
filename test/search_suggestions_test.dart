import 'package:flutter_test/flutter_test.dart';
import 'package:global_vms_tracker/screens/main_map_screen.dart';

void main() {
  group('buildCountrySuggestions', () {
    const countries = <String>[
      'Sri Lanka',
      'Singapore',
      'Sweden',
      'Norway',
      'South Africa',
      'Australia',
      'Austria',
    ];

    test('returns empty list for empty query', () {
      final result = buildCountrySuggestions(query: '  ', countryNames: countries);
      expect(result, isEmpty);
    });

    test('prioritizes startsWith before contains', () {
      final result = buildCountrySuggestions(query: 's', countryNames: countries);
      expect(result.take(4), ['Singapore', 'South Africa', 'Sri Lanka', 'Sweden']);
    });

    test('limits result size', () {
      final result = buildCountrySuggestions(
        query: 'a',
        countryNames: countries,
        maxResults: 2,
      );
      expect(result.length, 2);
    });
  });
}
