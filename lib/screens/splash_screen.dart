import 'package:flutter/material.dart';
import 'main_map_screen.dart'; // Map screen එක import කරන්න

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // තත්පර 3කට පසු සිතියමට මාරු වේ
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainMapScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("🌐", style: TextStyle(fontSize: 80)),
            SizedBox(height: 20),
            Text(
              "WORLD EXPLORER",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                color: Colors.cyan,
              ),
            ),
            SizedBox(height: 10),
            CircularProgressIndicator(strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}