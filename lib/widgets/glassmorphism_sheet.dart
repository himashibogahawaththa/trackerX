import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../services/webcam_service.dart';
import 'webcam_card.dart';

class GlassmorphismSheet extends StatefulWidget {
  final dynamic countryData;
  final Point location;

  const GlassmorphismSheet({
    super.key,
    required this.countryData,
    required this.location,
  });

  @override
  State<GlassmorphismSheet> createState() => _GlassmorphismSheetState();
}

class _GlassmorphismSheetState extends State<GlassmorphismSheet> {
  late Future<Map<String, dynamic>?> _webcamFuture;
  Future<String?>? _countryNameFuture;
  Timer? _autoRefreshTimer;

  String _getCleanText(dynamic value, {required String defaultValue}) {
    if (value == null) return defaultValue;
    String text = value.toString().trim();
    String upper = text.toUpperCase();
    if (text.isEmpty || upper == "N/A" || upper == "UNKNOWN" || upper == "NULL" || upper.contains("UNKNOWN")) {
      return defaultValue;
    }
    return text;
  }

  @override
  void initState() {
    super.initState();
    _webcamFuture = _loadWebcam();
    _startAutoRefresh();
    final bool isWebcamView = widget.countryData['isWebcam'] ?? false;
    final String countryCode = (widget.countryData['countryCode'] ?? '').toString().trim();
    final String existingName = _getCleanText(widget.countryData['name'], defaultValue: '');
    if (isWebcamView && existingName.isEmpty && countryCode.isNotEmpty) {
      _countryNameFuture = WebcamService.fetchCountryNameByCode(countryCode);
    }
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      if (!mounted) return;
      _retryWebcamFetch();
    });
  }

  Future<Map<String, dynamic>?> _loadWebcam() {
    return WebcamService.getWebcam(
      widget.location.coordinates[1]!.toDouble(),
      widget.location.coordinates[0]!.toDouble(),
    );
  }

  void _retryWebcamFetch() {
    setState(() {
      _webcamFuture = _loadWebcam();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine whether this sheet was opened from a webcam marker.
    bool isWebcamView = widget.countryData['isWebcam'] ?? false;

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
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Header Section (emoji + location metadata)
                  FutureBuilder<String?>(
                    future: _countryNameFuture,
                    builder: (context, snapshot) {
                      final resolvedName = _getCleanText(snapshot.data, defaultValue: '');
                      final fallbackName = _getCleanText(widget.countryData['name'], defaultValue: 'Not available');
                      final heading = (resolvedName.isNotEmpty ? resolvedName : fallbackName).toUpperCase();

                      return Row(
                        children: [
                          Text(widget.countryData['emoji'] ?? '🌍', style: const TextStyle(fontSize: 40)),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  heading,
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  isWebcamView
                                      ? "Location: ${_getCleanText(widget.countryData['city'], defaultValue: 'Not available')}"
                                      : "Capital: ${_getCleanText(widget.countryData['capital'], defaultValue: 'Not available')}",
                                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 25),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 20),

                  // Content Section
                  Row(
                    children: [
                      Icon(Icons.videocam, color: isWebcamView ? Colors.cyanAccent : Colors.redAccent, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        isWebcamView ? "WEBCAM DETAILS" : "LIVE CCTV FEED (WINDY)",
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // FutureBuilder for Webcam Data
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _webcamFuture,
                    builder: (context, snapshot) {
                      return WebcamCard(
                        webcamData: snapshot.data,
                        isLoading: snapshot.connectionState == ConnectionState.waiting,
                        hasError: snapshot.hasError,
                        onRetry: _retryWebcamFetch,
                      );
                    },
                  ),

                  const SizedBox(height: 30),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white30),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text("CLOSE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}