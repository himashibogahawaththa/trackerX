class Webcam {
  final String title;
  final double lat;
  final double lng;
  final String playerUrl;

  Webcam({required this.title, required this.lat, required this.lng, required this.playerUrl});

  factory Webcam.fromJson(Map<String, dynamic> json) {
    return Webcam(
      title: json['title'],
      lat: json['location']['latitude'], // JSON පථය නිවැරදිව මෙතැනට
      lng: json['location']['longitude'],
      playerUrl: json['player']['day'], // වීඩියෝ එක පෙන්වන URL එක
    );
  }
}