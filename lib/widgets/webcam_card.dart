import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WebcamCard extends StatelessWidget {
  final Map<String, dynamic>? webcamData;
  final bool isLoading;

  const WebcamCard({super.key, this.webcamData, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.cyan));
    }

    if (webcamData == null) {
      return const Center(
        child: Text("මෙම ප්‍රදේශයේ සජීවී කැමරා දත්ත නොමැත.",
            style: TextStyle(color: Colors.white70)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: CachedNetworkImage(
            imageUrl: webcamData!['image']['current']['preview'],
            placeholder: (context, url) => Container(
              height: 200,
              color: Colors.white10,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50, color: Colors.white24),
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "අවසන් වරට අලුත් වූයේ: ${webcamData!['last_updated'] ?? 'නොදනී'}",
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}