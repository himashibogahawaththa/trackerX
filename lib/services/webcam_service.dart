import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:global_vms_tracker/models/webcam_model.dart';
import 'package:http/http.dart' as http;

class WebcamService {
  // ⚡ Windy API Key
  static const String _apiKey = "MgXewnPr7WxSY3LnjYZbM7v2K88S2q4t";
  
  // ⚡ V3 Base URL
  static const String _baseUrl = "https://api.windy.com/webcams/api/v3/webcams";

  // 1. රට අනුව කැමරා සෙවීම (V3)
  static Future<List<Webcams>> fetchWebcams(String countryCode) async {
    // ✅ මෙහි 'include' එකට 'categories' එකතු කරන ලදී
    final url = Uri.parse(
        '$_baseUrl?countries=${countryCode.toUpperCase()}&limit=50&include=location,images,player,categories&lang=en');

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
        return webcamList.map((json) => Webcams.fromJson(json)).toList();
      } else {
        debugPrint("❌ Windy API Error (fetchWebcams): ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Network Error: $e");
    }
    return [];
  }

  // 2. ලක්ෂ්‍යයක් අවට කැමරා සෙවීම
  static Future<Map<String, dynamic>?> getWebcam(double lat, double lng) async {
    // ✅ මෙහි 'include' එකට 'categories' එකතු කරන ලදී
    final url = Uri.parse(
        '$_baseUrl?nearby=$lat,$lng,10&include=location,images,player,categories&limit=1');

    try {
      final response = await http.get(
        url, 
        headers: {
          'accept': 'application/json',
          'x-windy-api-key': _apiKey,
        }
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List webcams = data['webcams'] ?? []; 
        
        if (webcams.isNotEmpty) {
          return webcams.first;
        }
      } else {
        debugPrint("❌ Windy API Error (getWebcam): ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching specific webcam: $e");
    }
    return null;
  }
}