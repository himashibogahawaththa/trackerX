import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart'; // LatLng වෙනුවට Point සඳහා
import '../../services/webcam_service.dart';
import 'webcam_card.dart';

class GlassmorphismSheet extends StatelessWidget {
  final dynamic countryData;
  final Point location; // මෙතන LatLng වෙනුවට Point භාවිතා කරන්න

  const GlassmorphismSheet({
    super.key,
    required this.countryData,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.85,
      minChildSize: 0.4,
      builder: (_, controller) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white38,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  Row(
                    children: [
                      Text(countryData['emoji'] ?? '🌍', style: const TextStyle(fontSize: 40)),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (countryData['name'] ?? 'Unknown').toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              "Capital: ${countryData['capital'] ?? 'N/A'}",
                              style: const TextStyle(color: Colors.cyanAccent, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 20),

                  const Row(
                    children: [
                      Icon(Icons.videocam, color: Colors.redAccent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "LIVE CCTV FEED (WINDY)",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // GlassmorphismSheet එකේ FutureBuilder එක ඇතුළත:
FutureBuilder<Map<String, dynamic>?>(
  future: WebcamService.getWebcam(
    location.coordinates[1]!.toDouble(), // [1] යනු Latitude (y)
    location.coordinates[0]!.toDouble(), // [0] යනු Longitude (x)
  ),
  builder: (context, snapshot) {
    return WebcamCard(
      webcamData: snapshot.data,
      isLoading: snapshot.connectionState == ConnectionState.waiting,
    );
  },
),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white30),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text("CLOSE", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}