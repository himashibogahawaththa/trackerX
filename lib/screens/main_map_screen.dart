import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:global_vms_tracker/models/webcam_model.dart';
import 'package:global_vms_tracker/services/webcam_service.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/graphql_service.dart';
import '../widgets/glassmorphism_sheet.dart';

class MainMapScreen extends StatefulWidget {
  const MainMapScreen({super.key});

  @override
  State<MainMapScreen> createState() => _MainMapScreenState();
}

class _MainMapScreenState extends State<MainMapScreen> {
  MapboxMap? mapboxMap;
  Uint8List? markerIconBytes;

  PointAnnotationManager? countryManager;
  PointAnnotationManager? webcamManager;

  bool _isMarkersAdded = false;
  bool _isLoading = false; // loader state
  List<dynamic> _countries = [];
  Map<String, List<dynamic>> coordsData = {};

  @override
  void initState() {
    super.initState();
    _preloadAssets();
  }

  Future<void> _preloadAssets() async {
    try {
      final ByteData bytes = await rootBundle.load('assets/symbols/custom-icon.png');
      markerIconBytes = bytes.buffer.asUint8List();

      final String response = await rootBundle.loadString('assets/data/country_coords.json');
      coordsData = Map<String, List<dynamic>>.from(json.decode(response));
    } catch (e) {
      print("❌ Preload error: $e");
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;

    // Country marker manager
    mapboxMap.annotations.createPointAnnotationManager().then((manager) async {
      setState(() => countryManager = manager);
      await manager.setTextAllowOverlap(true);
      await manager.setTextIgnorePlacement(true);
      manager.addOnPointAnnotationClickListener(
        _AnnotationClickListener(onAnnotationClick: _onMarkerTapped),
      );
    });

    // Webcam marker manager
    mapboxMap.annotations.createPointAnnotationManager().then((manager) async {
      setState(() => webcamManager = manager);
      await manager.setIconAllowOverlap(true);
      await manager.setIconIgnorePlacement(true);
      await manager.setSymbolSortKey(10.0);
      manager.addOnPointAnnotationClickListener(
        _AnnotationClickListener(onAnnotationClick: _onMarkerTapped),
      );
    });
  }

  void _onMarkerTapped(PointAnnotation annotation) {
    final data = annotation.customData;
    if (data != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => GlassmorphismSheet(
          countryData: Map<String, dynamic>.from(data as Map),
          location: annotation.geometry,
        ),
      );
    }
  }

  void _addMarkers(List<dynamic> countries) async {
    if (countryManager == null || _isMarkersAdded) return;
    _countries = countries;
    _isMarkersAdded = true;

    setState(() => _isLoading = true); // show loader

    try {
      List<PointAnnotationOptions> options = [];
      List<dynamic> validCountries = [];

      for (var country in countries) {
        String name = country['name'] ?? "";
        if (coordsData.containsKey(name)) {
          List coords = coordsData[name]!;
          validCountries.add(country);

          options.add(PointAnnotationOptions(
            geometry: Point(coordinates: Position(coords[1], coords[0])),
            textField: country['emoji'],
            textSize: 28,
          ));
        }
      }

      final annotations = await countryManager!.createMulti(options);

      for (int i = 0; i < annotations.length; i++) {
        annotations[i]?.customData = Map<String, Object>.from(validCountries[i]);
      }

      print("✅ Countries added successfully");
    } catch (e) {
      print("❌ Country error: $e");
      _isMarkersAdded = false;
    }

    setState(() => _isLoading = false); // hide loader
  }

  void _handleSearch(String value) async {
    if (value.isEmpty) return;

    try {
      String searchKey = coordsData.keys.firstWhere(
        (k) => k.toLowerCase() == value.toLowerCase().trim(),
        orElse: () => "",
      );

      if (searchKey.isNotEmpty) {
        List coords = coordsData[searchKey]!;

        mapboxMap?.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(coords[1], coords[0])),
            zoom: 6,
          ),
          MapAnimationOptions(duration: 2000),
        );

        String countryCode = "";
        for (var c in _countries) {
          if (c['name'].toLowerCase() == searchKey.toLowerCase()) {
            countryCode = c['code'];
            break;
          }
        }

        if (countryCode.isNotEmpty) _fetchAndShowWebcams(countryCode);
      }
    } catch (e) {
      print("Search error: $e");
    }
  }

  void _fetchAndShowWebcams(String countryCode) async {
    try {
      final List<Webcam> webcams = await WebcamService.fetchWebcams(countryCode);

      if (!mounted || webcams.isEmpty || webcamManager == null) {
        print("⚠️ No webcams found or manager not ready.");
        return;
      }

      setState(() => _isLoading = true); // show loader

      await webcamManager!.deleteAll();

      List<PointAnnotationOptions> webcamMarkers = [];
      for (var cam in webcams) {
        webcamMarkers.add(PointAnnotationOptions(
          geometry: Point(coordinates: Position(cam.lng, cam.lat)),
          image: markerIconBytes,
          iconSize: 0.1,
          iconAnchor: IconAnchor.CENTER,
        ));
      }

      final annotations = await webcamManager!.createMulti(webcamMarkers);

      for (int i = 0; i < annotations.length; i++) {
        annotations[i]?.customData = {
          "title": webcams[i].title,
          "url": webcams[i].playerUrl,
          "isWebcam": true,
        };
      }

      setState(() => _isLoading = false);
      print("✅ Successfully added ${webcams.length} webcams.");
    } catch (e) {
      setState(() => _isLoading = false);
      print("❌ Webcam error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey("mapWidget"),
            onMapCreated: _onMapCreated,
            styleUri: MapboxStyles.LIGHT,
          ),

          // GraphQL query for countries
          Query(
            options: QueryOptions(
              document: gql(GraphQLService.getCountriesQuery),
              fetchPolicy: FetchPolicy.cacheFirst,
            ),
            builder: (result, {refetch, fetchMore}) {
              if (!result.isLoading && !result.hasException && countryManager != null) {
                final countries = result.data?['countries'] ?? [];
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _addMarkers(countries);
                });
              }
              return const SizedBox.shrink();
            },
          ),

          _buildTopBar(),

          // Loader overlay
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(30),
        ),
        child: TextField(
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Search Countries (e.g. Italy)...",
            hintStyle: TextStyle(color: Colors.white38),
            prefixIcon: Icon(Icons.search, color: Colors.cyanAccent),
            border: InputBorder.none,
          ),
          onSubmitted: _handleSearch,
        ),
      ),
    );
  }
}

class _AnnotationClickListener extends OnPointAnnotationClickListener {
  final Function(PointAnnotation) onAnnotationClick;
  _AnnotationClickListener({required this.onAnnotationClick});

  @override
  bool onPointAnnotationClick(PointAnnotation annotation) {
    onAnnotationClick(annotation);
    return true;
  }
}