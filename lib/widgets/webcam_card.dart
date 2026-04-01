import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:global_vms_tracker/screens/webcam_player_screen.dart';

class WebcamCard extends StatelessWidget {
  final Map<String, dynamic>? webcamData;
  final bool isLoading;

  const WebcamCard({super.key, this.webcamData, required this.isLoading});

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

    // 🔴 Empty Data Handling (ශ්‍රී ලංකාව වගේ දත්ත නැති තැන් සඳහා)
    if (webcamData == null || 
        webcamData!.isEmpty || 
        (webcamData!.containsKey('total') && webcamData!['total'] == 0)) {
      return _buildNoDataMessage();
    }

    // දත්ත නිවැරදිව කියවා ගැනීම සහ N/A handle කිරීම
    final dynamic rawTitle = webcamData?['title'];
    String displayTitle = "තොරතුරු ලබාගත නොහැක";
    
    if (rawTitle != null && rawTitle.toString().isNotEmpty) {
      String titleStr = rawTitle.toString().toUpperCase();
      if (titleStr != "N/A" && titleStr != "UNKNOWN") {
        displayTitle = rawTitle.toString();
      }
    }

    final String? imageUrl = webcamData?['images']?['current']?['preview'];
    final String? updateTime = webcamData?['lastUpdatedOn'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // මාතෘකාව සහ Live Badge එක
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
          ],
        ),
        const SizedBox(height: 12),

        // සජීවී රූපරාමුව (Preview Image)
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  placeholder: (context, url) => _buildImagePlaceholder(),
                  errorWidget: (context, url, error) => _buildErrorWidget(),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 180,
                )
              : _buildErrorWidget(),
        ),

        const SizedBox(height: 10),

        // අවසන් වරට යාවත්කාලීන වූ වෙලාව
        Row(
          children: [
            const Icon(Icons.access_time, size: 14, color: Colors.white54),
            const SizedBox(width: 5),
            Text(
              "අවසන් වරට යාවත්කාලීන වූයේ: ${_formatDate(updateTime)}",
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),

        const SizedBox(height: 20),
        const Text(
          "විකාශන කාලරාමුව තෝරන්න:",
          style: TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),

        // බටන් Grid එක (ලින්ක් එක නැතිනම් Disable වේ)
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 3.2,
          children: [
            _buildPlayerButton(context, "සජීවී (Live)", webcamData?['player']?['live'], Icons.live_tv, Colors.redAccent),
            _buildPlayerButton(context, "අද (Day)", webcamData?['player']?['day'], Icons.today, Colors.orangeAccent),
            _buildPlayerButton(context, "මාසය (Month)", webcamData?['player']?['month'], Icons.calendar_month, Colors.blueAccent),
            _buildPlayerButton(context, "වසර (Year)", webcamData?['player']?['year'], Icons.history, Colors.greenAccent),
          ],
        ),

        const SizedBox(height: 10),
        
        // Lifetime බටන් එක (Full Width)
        _buildPlayerButton(
          context, 
          "සම්පූර්ණ කාලය (Lifetime)", 
          webcamData?['player']?['lifetime'], 
          Icons.all_inclusive, 
          Colors.purpleAccent, 
          isFullWidth: true
        ),
      ],
    );
  }

  // බටන් එක නිර්මාණය කරන පොදු Method එක
  Widget _buildPlayerButton(BuildContext context, String label, String? url, IconData icon, Color color, {bool isFullWidth = false}) {
    // URL එක null/empty/NA නම් disable වේ
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
          backgroundColor: isDisabled ? Colors.white.withValues(alpha: 0.05) : color.withValues(alpha: 0.1),
          foregroundColor: isDisabled ? Colors.white12 : color,
          side: BorderSide(color: isDisabled ? Colors.white10 : color.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          elevation: 0,
        ),
        onPressed: isDisabled ? null : () {
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
        icon: Icon(icon, size: 16, color: isDisabled ? Colors.white12 : color),
        label: Text(
          label, 
          style: TextStyle(
            fontSize: 11, 
            fontWeight: FontWeight.bold,
            color: isDisabled ? Colors.white12 : color
          )
        ),
      ),
    );
  }

  // දිනය format කරන ආකාරය
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "දැනට වාර්තා වී නැත";
    
    String checkStr = dateStr.toUpperCase();
    if (checkStr == "UNKNOWN" || checkStr == "N/A") return "දැනට වාර්තා වී නැත";

    try {
      return dateStr.split('T')[0];
    } catch (e) {
      return "දත්ත දෝෂයකි";
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
          Text("සජීවී රූපරාමු ලබාගත නොහැක", style: TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }

  // 🔴 ලස්සන Empty State Message එකක්
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
              "දත්ත කිසිවක් හමු නොවීය",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "මෙම ප්‍රදේශයේ සජීවී වෙබ් කැමරා දත්ත දැනට පද්ධතියේ වාර්තා වී නොමැත.",
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
}