import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:global_vms_tracker/models/webcam_model.dart';
import 'package:http/http.dart' as http;

class WebcamService {
  // Windy API key
  static const String _apiKey = "MgXewnPr7WxSY3LnjYZbM7v2K88S2q4t";

  // Windy v3 base URL
  static const String _baseUrl = "https://api.windy.com/webcams/api/v3/webcams";
  static const Map<String, String> _noCacheHeaders = {
    'accept': 'application/json',
    'x-windy-api-key': _apiKey,
    'Cache-Control': 'no-cache, no-store, must-revalidate',
    'Pragma': 'no-cache',
    'Expires': '0',
  };

  // Fetch webcams for a specific country.
  static Future<List<Webcams>> fetchWebcams(String countryCode) async {
    final url = Uri.parse(
        '$_baseUrl?countries=${countryCode.toUpperCase()}&limit=50&include=location,images,player,categories&lang=en&_ts=${DateTime.now().millisecondsSinceEpoch}');

    try {
      final response = await http.get(url, headers: _noCacheHeaders).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> webcamList = data['webcams'] ?? [];
        return webcamList.map((json) => Webcams.fromJson(json)).toList();
      }
      throw Exception("Windy API returned ${response.statusCode} while loading country webcams.");
    } catch (e) {
      debugPrint("Windy country webcams error: $e");
      rethrow;
    }
  }

  // Fetch the nearest webcam around a point.
  static Future<Map<String, dynamic>?> getWebcam(double lat, double lng) async {
    final url = Uri.parse(
        '$_baseUrl?nearby=$lat,$lng,10&include=location,images,player,categories&limit=1&_ts=${DateTime.now().millisecondsSinceEpoch}');

    try {
      final response = await http.get(url, headers: _noCacheHeaders).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> webcams = data['webcams'] ?? [];
        if (webcams.isNotEmpty) {
          return Map<String, dynamic>.from(webcams.first as Map);
        }
        return null;
      }
      throw Exception("Windy API returned ${response.statusCode} while loading nearby webcam.");
    } catch (e) {
      debugPrint("Windy nearby webcam error: $e");
      rethrow;
    }
  }

  // Resolve country name from ISO country code using GraphQL endpoint.
  static Future<String?> fetchCountryNameByCode(String countryCode) async {
    final code = countryCode.trim().toUpperCase();
    if (code.isEmpty) return null;
    final uri = Uri.parse('https://countries.trevorblades.com/');
    const query = '''
      query CountryByCode(\$code: ID!) {
        country(code: \$code) {
          name
        }
      }
    ''';

    try {
      final response = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: json.encode({
          'query': query,
          'variables': {'code': code},
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception("Country lookup API returned ${response.statusCode}.");
      }

      final Map<String, dynamic> payload = json.decode(response.body);
      final Map<String, dynamic>? data = payload['data'] as Map<String, dynamic>?;
      final Map<String, dynamic>? country = data?['country'] as Map<String, dynamic>?;
      return country?['name'] as String?;
    } catch (e) {
      debugPrint("Country name lookup error: $e");
      return null;
    }
  }

  // Warm the latest preview image into HTTP/cache layers without blocking UI.
  static Future<void> prefetchPreviewImage(String imageUrl) async {
    if (imageUrl.trim().isEmpty) return;
    try {
      final uri = Uri.parse(
        "$imageUrl${imageUrl.contains('?') ? '&' : '?'}_ts=${DateTime.now().millisecondsSinceEpoch}",
      );
      await http.get(uri, headers: _noCacheHeaders).timeout(const Duration(seconds: 15));
    } catch (_) {
      // Best-effort prefetch; failures are non-fatal.
    }
  }
}