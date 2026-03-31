import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  static const String mapboxToken = 'pk.eyJ1IjoiaGF6ZWxsbGxsbCIsImEiOiJjbW44MWVqM3IwNnY5MnBxcjg1YXcxZXMyIn0.MG8cXDNeci47K_xRGWZ8Dw';

  static Future<List<double>?> getCoordinates(String city) async {
    final url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/$city.json?access_token=$mapboxToken';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['features'].isNotEmpty) {
        return List<double>.from(data['features'][0]['center']); // [lng, lat]
      }
    }
    return null;
  }
}