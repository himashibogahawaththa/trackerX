import 'dart:io'; // 1. HttpOverrides සඳහා අනිවාර්යයි
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'screens/splash_screen.dart';

// 2. SSL/Handshake ගැටලුව විසඳීමට මෙය එක් කරන්න
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  // Flutter Engine එක initialize කිරීම
  WidgetsFlutterBinding.ensureInitialized();

  // 3. SSL Handshake Bypass කිරීම මෙතැනදී ක්‍රියාත්මක කරන්න
  HttpOverrides.global = MyHttpOverrides();

  // Mapbox Access Token එක ලබා දීම
  MapboxOptions.setAccessToken('pk.eyJ1IjoiaGF6ZWxsbGxsbCIsImEiOiJjbW44MWVqM3IwNnY5MnBxcjg1YXcxZXMyIn0.MG8cXDNeci47K_xRGWZ8Dw');

  await initHiveForFlutter();

  final HttpLink httpLink = HttpLink('https://countries.trevorblades.com/');

  final ValueNotifier<GraphQLClient> client = ValueNotifier(
    GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(store: HiveStore()),
    ),
  );

  runApp(
    GraphQLProvider(
      client: client,
      child: const WorldExplorerApp(),
    ),
  );
}

class WorldExplorerApp extends StatelessWidget {
  const WorldExplorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Global VMS Tracker', // App එකේ නම මෙතැනත් වෙනස් කළා
      debugShowCheckedModeBanner: false,
      
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.cyan,
        scaffoldBackgroundColor: const Color(0xFF1A1A2E), 
        fontFamily: 'Roboto', 
      ),
      
      home: const SplashScreen(),
    );
  }
}