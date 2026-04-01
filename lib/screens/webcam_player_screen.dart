import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebcamPlayerScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebcamPlayerScreen({super.key, required this.url, required this.title});

  @override
  State<WebcamPlayerScreen> createState() => _WebcamPlayerScreenState();
}

class _WebcamPlayerScreenState extends State<WebcamPlayerScreen> {
  late final WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url)); // Windy Player URL එක load කරනවා
  }

  @override
void dispose() {
  // WebView එක අයින් වන විට memory නිදහස් කිරීමට (V4 වල මෙය ස්වයංක්‍රීයව බොහෝ දුරට සිදුවේ)
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
        ],
      ),
    );
  }
}