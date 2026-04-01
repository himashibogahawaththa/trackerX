import 'package:flutter_test/flutter_test.dart';
import 'package:global_vms_tracker/models/webcam_model.dart';

void main() {
  group('Location.fromJson', () {
    test('parses int coordinates as double', () {
      final location = Location.fromJson({
        'latitude': 10,
        'longitude': 20,
      });

      expect(location.latitude, 10.0);
      expect(location.longitude, 20.0);
    });

    test('parses double coordinates correctly', () {
      final location = Location.fromJson({
        'latitude': 6.9271,
        'longitude': 79.8612,
      });

      expect(location.latitude, 6.9271);
      expect(location.longitude, 79.8612);
    });

    test('keeps null coordinates as null', () {
      final location = Location.fromJson({
        'latitude': null,
        'longitude': null,
      });

      expect(location.latitude, isNull);
      expect(location.longitude, isNull);
    });
  });
}
