import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../models/webcam_model.dart';
import '../services/webcam_service.dart';
import '../services/graphql_service.dart';
import '../widgets/glassmorphism_sheet.dart';

List<Webcams> filterWebcamsWithCoordinates(List<Webcams> webcams) {
  return webcams.where((cam) {
    return cam.location?.latitude != null && cam.location?.longitude != null;
  }).toList();
}

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
  Cancelable? _countryTapEvents;
  Cancelable? _webcamTapEvents;

  bool _isMarkersAdded = false;
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _searchSuggestions = [];
  bool _showSuggestions = false;

  List<dynamic> _countries = [];
  Map<String, List<dynamic>> coordsData = {};

  @override
  void initState() {
    super.initState();
    _preloadAssets();
    _searchController.addListener(_handleSearchInputChanged);
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus && mounted) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  /// Pre-loading assets and local JSON data for performance optimization
  Future<void> _preloadAssets() async {
    try {
      final ByteData bytes = await rootBundle.load('assets/symbols/custom-icon.png');
      markerIconBytes = bytes.buffer.asUint8List();

      final String response = await rootBundle.loadString('assets/data/country_coords.json');
      coordsData = Map<String, List<dynamic>>.from(json.decode(response));
    } catch (e) {
      debugPrint("❌ Preload error: $e");
    }
  }

  void _onMapCreated(MapboxMap map) {
    mapboxMap = map;

    /// Initialize Annotation Managers
    map.annotations.createPointAnnotationManager().then((manager) {
      if (!mounted) return;
      countryManager = manager;
      manager.setTextAllowOverlap(true);
      manager.setTextIgnorePlacement(true);
      _countryTapEvents?.cancel();
      _countryTapEvents = manager.tapEvents(onTap: _onPointAnnotationTap);
    });

    map.annotations.createPointAnnotationManager().then((manager) {
      if (!mounted) return;
      webcamManager = manager;
      manager.setIconAllowOverlap(true);
      manager.setIconIgnorePlacement(true);
      manager.setSymbolSortKey(10.0);
      _webcamTapEvents?.cancel();
      _webcamTapEvents = manager.tapEvents(onTap: _onPointAnnotationTap);
    });
  }

  void _onPointAnnotationTap(PointAnnotation annotation) {
    final data = annotation.customData;
    if (data == null) return;
    final Map<dynamic, dynamic> mapData = data;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassmorphismSheet(
        countryData: Map<String, dynamic>.from(mapData),
        location: annotation.geometry,
      ),
    );
  }

  /// Refactored Marker Addition with validation
  void _addCountryMarkers(List<dynamic> countries) async {
    if (countryManager == null || _isMarkersAdded) return;

    _countries = countries;
    _isMarkersAdded = true;

    try {
      List<PointAnnotationOptions> options = [];

      for (var country in countries) {
        String name = country['name'] ?? "";
        if (coordsData.containsKey(name)) {
          List coords = coordsData[name]!;
          final Map countryMap = country as Map;
          final Map<String, Object> customData = countryMap.entries
              .where((entry) => entry.key is String && entry.value != null)
              .fold<Map<String, Object>>({}, (acc, entry) {
            acc[entry.key as String] = entry.value as Object;
            return acc;
          });
          options.add(
            PointAnnotationOptions(
              geometry: Point(coordinates: Position(coords[1], coords[0])),
              textField: country['emoji'],
              textSize: 28,
              customData: customData,
            ),
          );
        }
      }
      await countryManager!.createMulti(options);
    } catch (e) {
      debugPrint("❌ Country markers error: $e");
      _isMarkersAdded = false;
    }
  }

  /// Fetch and render webcam markers based on selected country code
  void _fetchAndShowWebcams(String countryCode) async {
    setState(() => _isLoading = true);
    try {
      final List<Webcams> webcams = await WebcamService.fetchWebcams(countryCode);

      if (!mounted || webcamManager == null) return;

      await webcamManager!.deleteAll();

      final validWebcams = filterWebcamsWithCoordinates(webcams);

      if (validWebcams.isEmpty) {
        _showSnackBar("No active webcams found in this region.");
      } else {
        List<PointAnnotationOptions> webcamMarkers = validWebcams.map((cam) {
          return PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(
                cam.location!.longitude!,
                cam.location!.latitude!,
              ),
            ),
            image: markerIconBytes,
            iconSize: 0.08,
            customData: {
              "title": cam.title ?? "Unknown Webcam",
              "countryCode": countryCode, // To handle region-specific data
              "isWebcam": true,
            },
          );
        }).toList();

        await webcamManager!.createMulti(webcamMarkers);
      }
    } catch (e) {
      debugPrint("❌ Webcam fetch error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleSearch(String value) {
    if (value.isEmpty) return;
    
    final searchKey = coordsData.keys.firstWhere(
      (k) => k.toLowerCase() == value.toLowerCase().trim(),
      orElse: () => "",
    );

    if (searchKey.isNotEmpty) {
      final coords = coordsData[searchKey]!;
      
      mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(coords[1], coords[0])),
          zoom: 6,
        ),
        MapAnimationOptions(duration: 2000),
      );

      final country = _countries.firstWhere(
        (c) => c['name'].toLowerCase() == searchKey.toLowerCase(),
        orElse: () => null,
      );

      if (country != null) {
        _fetchAndShowWebcams(country['code']);
      }
      if (mounted) {
        setState(() {
          _showSuggestions = false;
        });
      }
    } else {
      _showSnackBar("No country found for \"$value\".");
    }
  }

  void _handleSearchInputChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _searchSuggestions = [];
          _showSuggestions = false;
        });
      }
      return;
    }

    final keys = coordsData.keys.toList();
    final startsWith = keys
        .where((k) => k.toLowerCase().startsWith(query))
        .toList()
      ..sort();
    final contains = keys
        .where((k) => !startsWith.contains(k) && k.toLowerCase().contains(query))
        .toList()
      ..sort();

    if (mounted) {
      setState(() {
        _searchSuggestions = [...startsWith, ...contains].take(6).toList();
        _showSuggestions = _searchFocusNode.hasFocus;
      });
    }
  }

  void _selectCountry(String country) {
    _searchController.text = country;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: country.length),
    );
    _handleSearch(country);
    _searchFocusNode.unfocus();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    _countryTapEvents?.cancel();
    _webcamTapEvents?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent map distortion when keyboard opens
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey("mapWidget"),
            onMapCreated: _onMapCreated,
            styleUri: MapboxStyles.STANDARD,
          ),

          /// GraphQL Data Integration
          Query(
            options: QueryOptions(
              document: gql(GraphQLService.getCountriesQuery),
              fetchPolicy: FetchPolicy.cacheFirst,
            ),
            builder: (result, {refetch, fetchMore}) {
              if (!result.isLoading && !result.hasException && countryManager != null) {
                final countries = result.data?['countries'] ?? [];
                WidgetsBinding.instance.addPostFrameCallback((_) => _addCountryMarkers(countries));
              }
              return const SizedBox.shrink();
            },
          ),

          _buildTopSearchBar(),

          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
        ],
      ),
    );
  }

  Widget _buildTopSearchBar() {
    return Positioned(
      top: 60,
      left: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)],
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search country...",
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.cyanAccent),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onSubmitted: _handleSearch,
            ),
          ),
          if (_showSuggestions)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF121224).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: _searchSuggestions.isEmpty
                  ? const ListTile(
                      dense: true,
                      leading: Icon(Icons.info_outline, color: Colors.white38, size: 18),
                      title: Text(
                        "No matching countries",
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _searchSuggestions.map((country) {
                        return ListTile(
                          dense: true,
                          title: Text(
                            country,
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: () => _selectCountry(country),
                        );
                      }).toList(),
                    ),
            ),
        ],
      ),
    );
  }
}