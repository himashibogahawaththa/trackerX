import 'package:flutter_test/flutter_test.dart';
import 'package:global_vms_tracker/models/webcam_model.dart';
import 'package:global_vms_tracker/screens/main_map_screen.dart';

void main() {
  group('filterWebcamsWithCoordinates', () {
    test('keeps only webcams with both latitude and longitude', () {
      final webcams = <Webcams>[
        Webcams(
          title: 'valid',
          location: Location(latitude: 6.9, longitude: 79.8),
        ),
        Webcams(
          title: 'missing lat',
          location: Location(latitude: null, longitude: 79.8),
        ),
        Webcams(
          title: 'missing lng',
          location: Location(latitude: 6.9, longitude: null),
        ),
        Webcams(
          title: 'missing location',
          location: null,
        ),
      ];

      final filtered = filterWebcamsWithCoordinates(webcams);

      expect(filtered.length, 1);
      expect(filtered.first.title, 'valid');
    });
  });
}
