import 'dart:convert';
import 'package:global_vms_tracker/models/webcam_model.dart';
import 'package:http/http.dart' as http;
// Path එක නිවැරදිව පරීක්ෂා කරන්න

class WebcamService {
  static const String _apiKey = "MgXewnPr7WxSY3LnjYZbM7v2K88S2q4t";
  static const String _baseUrl = "https://api.windy.com/webcams/api/v3/webcams";

  static Future<List<Webcam>> fetchWebcams(String countryCode) async {
    final url = Uri.parse('$_baseUrl?countries=${countryCode.toUpperCase()}&limit=50&include=location,images,player&lang=en');

    try {
      final response = await http.get(
        url, 
        headers: {
          'accept': 'application/json',
          'x-windy-api-key': _apiKey,
        }
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> webcamList = data['webcams'] ?? [];
        
        // JSON දත්ත Webcam objects බවට පත් කිරීම
        return webcamList.map((json) => Webcam.fromJson(json)).toList();
      } else {
        print("Windy API Error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Network Error: $e");
    }
    return [];
  }


  static Future<Map<String, dynamic>?> getWebcam(double lat, double lng) async {
  // නිශ්චිත ලක්ෂ්‍යයක් වටා (Radius 10km) තියෙන කැමරා සෙවීම
  final url = Uri.parse(
      'https://api.windy.com/api/webcams/v2/list/nearby=$lat,$lng,10?show=webcams:image,location,player');

  try {
    final response = await http.get(url, headers: {'x-windy-key': _apiKey});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List webcams = data['result']['webcams'] ?? [];
      
      // ලැයිස්තුවේ පළමු කැමරාව පමණක් ලබා දීම
      if (webcams.isNotEmpty) {
        return webcams.first;
      }
    }
  } catch (e) {
    print("Error fetching specific webcam: $e");
  }
  return null;
}
}