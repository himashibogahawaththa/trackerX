import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:global_vms_tracker/screens/webcam_player_screen.dart';

class WebcamCard extends StatelessWidget {
  final Map<String, dynamic>? webcamData;
  final bool isLoading;
  final bool hasError;
  final VoidCallback? onRetry;

  const WebcamCard({
    super.key,
    this.webcamData,
    required this.isLoading,
    this.hasError = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: CircularProgressIndicator(color: Colors.cyanAccent),
        ),
      );
    }

    if (hasError) {
      return _buildErrorState();
    }

    // Handle cases where the API returns no webcam records.
    if (webcamData == null || 
        webcamData!.isEmpty || 
        (webcamData!.containsKey('total') && webcamData!['total'] == 0)) {
      return _buildNoDataMessage();
    }

    // Resolve title from API fields with graceful fallback.
    final dynamic rawTitle = webcamData?['title'];
    final dynamic webcamId = webcamData?['webcamId'];
    String displayTitle = webcamId != null ? "Webcam #$webcamId" : "Webcam details unavailable";

    if (rawTitle != null && rawTitle.toString().isNotEmpty) {
      String titleStr = rawTitle.toString().toUpperCase();
      if (titleStr != "N/A" && titleStr != "UNKNOWN") {
        displayTitle = rawTitle.toString();
      }
    }

    final String? imageUrl = webcamData?['images']?['current']?['preview'];
    final String? updateTime = webcamData?['lastUpdatedOn'];
    final String imageCacheKey = webcamData?['webcamId'] != null
        ? "${webcamData!['webcamId']}-${updateTime ?? DateTime.now().millisecondsSinceEpoch}"
        : (updateTime ?? DateTime.now().millisecondsSinceEpoch.toString());
    final String? imageUrlWithBust = imageUrl == null
        ? null
        : "$imageUrl${imageUrl.contains('?') ? '&' : '?'}_ts=${DateTime.now().millisecondsSinceEpoch}";

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
        // Title and live badge
        Row(
          children: [
            Expanded(
              child: Text(
                displayTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (webcamData?['player']?['live'] != null)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "LIVE", 
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                ),
              ),
            if (onRetry != null)
              IconButton(
                tooltip: "Refresh feed",
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, color: Colors.cyanAccent, size: 18),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Live preview image
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: imageUrlWithBust != null
              ? CachedNetworkImage(
                  imageUrl: imageUrlWithBust,
                  cacheKey: imageCacheKey,
                  placeholder: (context, url) => _buildImagePlaceholder(),
                  errorWidget: (context, url, error) => _buildErrorWidget(),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 180,
                )
              : _buildErrorWidget(),
        ),

        const SizedBox(height: 10),

        // Last updated time
        Row(
          children: [
            const Icon(Icons.access_time, size: 14, color: Colors.white54),
            const SizedBox(width: 5),
            Text(
              "Last updated: ${_formatDate(updateTime)}",
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),

        const SizedBox(height: 18),
        _buildPlayerButton(
          context,
          "Live",
          webcamData?['player']?['live'],
          Icons.live_tv,
          Colors.redAccent,
          isFullWidth: true,
          isPrimary: true,
        ),

        const SizedBox(height: 12),
        const Text(
          "Choose timeline:",
          style: TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),

        // Timeline grid (disabled when API URL is missing)
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 3.2,
          children: [
            _buildPlayerButton(context, "Today", webcamData?['player']?['day'], Icons.today, Colors.orangeAccent),
            _buildPlayerButton(context, "Month", webcamData?['player']?['month'], Icons.calendar_month, Colors.blueAccent),
            _buildPlayerButton(context, "Year", webcamData?['player']?['year'], Icons.history, Colors.greenAccent),
            _buildPlayerButton(context, "All Time", webcamData?['player']?['lifetime'], Icons.all_inclusive, Colors.purpleAccent),
          ],
        ),
      ],
      ),
    );
  }

  // Shared player button builder.
  Widget _buildPlayerButton(
    BuildContext context,
    String label,
    String? url,
    IconData icon,
    Color color, {
    bool isFullWidth = false,
    bool isPrimary = false,
  }) {
    // Disable when URL is null, empty, or placeholder-like.
    bool isDisabled = (url == null || url.isEmpty);
    if (!isDisabled) {
      String urlUpper = url.toString().toUpperCase();
      if (urlUpper == "N/A" || urlUpper == "UNKNOWN") {
        isDisabled = true;
      }
    }

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled
              ? Colors.white.withValues(alpha: 0.05)
              : isPrimary
                  ? color.withValues(alpha: 0.9)
                  : color.withValues(alpha: 0.14),
          foregroundColor: isDisabled ? Colors.white12 : (isPrimary ? Colors.white : color),
          side: BorderSide(color: isDisabled ? Colors.white10 : color.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          elevation: 0,
        ),
        onPressed: () {
          if (isDisabled) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("This stream is not available right now."),
                backgroundColor: Colors.orangeAccent,
              ),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebcamPlayerScreen(
                url: url!,
                title: label,
              ),
            ),
          );
        },
        icon: Icon(icon, size: 16, color: isDisabled ? Colors.white12 : (isPrimary ? Colors.white : color)),
        label: Text(
          label, 
          style: TextStyle(
            fontSize: 11, 
            fontWeight: FontWeight.bold,
            color: isDisabled ? Colors.white12 : (isPrimary ? Colors.white : color),
          )
        ),
      ),
    );
  }

  // Format date output safely.
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "No recent update";
    
    String checkStr = dateStr.toUpperCase();
    if (checkStr == "UNKNOWN" || checkStr == "N/A") return "No recent update";

    try {
      return dateStr.split('T')[0];
    } catch (e) {
      return "Invalid date value";
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      color: Colors.white.withValues(alpha: 0.05),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent)),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      height: 180,
      width: double.infinity,
      color: Colors.white.withValues(alpha: 0.05),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off, size: 40, color: Colors.white24),
          SizedBox(height: 8),
          Text("Live preview unavailable", style: TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }

  // Empty state when no webcam is available for the selected area.
  Widget _buildNoDataMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 50,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            const Text(
              "No webcam data found",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "There are no active webcams reported for this area at the moment.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 42, color: Colors.orangeAccent),
            const SizedBox(height: 10),
            const Text(
              "Could not load webcam details.",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              "Check your connection and try again.",
              style: TextStyle(color: Colors.white60, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
              label: const Text("Retry", style: TextStyle(color: Colors.cyanAccent)),
            ),
          ],
        ),
      ),
    );
  }
}