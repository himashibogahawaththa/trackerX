import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'screens/splash_screen.dart';

/// Global Configuration constants for better maintainability
class AppConfig {
  static const String mapboxToken = 'pk.eyJ1IjoiaGF6ZWxsbGxsbCIsImEiOiJjbW44MWVqM3IwNnY5MnBxcjg1YXcxZXMyIn0.MG8cXDNeci47K_xRGWZ8Dw';
  static const String graphqlEndpoint = 'https://countries.trevorblades.com/';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Handle SSL handshake errors only in development mode to maintain security in production
  if (kDebugMode) {
    HttpOverrides.global = DevHttpOverrides();
  }

  /// Initialize Mapbox with the access token
  MapboxOptions.setAccessToken(AppConfig.mapboxToken);

  /// Initialize Hive for GraphQL caching to improve offline performance
  await initHiveForFlutter();

  final HttpLink httpLink = HttpLink(AppConfig.graphqlEndpoint);
  
  final ValueNotifier<GraphQLClient> client = ValueNotifier(
    GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(store: HiveStore()),
    ),
  );

  runApp(
    GraphQLProvider(
      client: client,
      child: const GlobalWebcamMonitorApp(),
    ),
  );
}

/// Custom HttpOverrides to bypass self-signed certificate errors during development
class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class GlobalWebcamMonitorApp extends StatelessWidget {
  const GlobalWebcamMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Global Webcam Monitor',
      debugShowCheckedModeBanner: false,
      
      /// Implementing a modern Dark Theme using Material 3
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyanAccent,
          brightness: Brightness.dark,
          surface: const Color(0xFF1A1A2E), 
          primary: Colors.cyanAccent,
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        fontFamily: 'Roboto',
        
        /// Typography optimization for better readability
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}