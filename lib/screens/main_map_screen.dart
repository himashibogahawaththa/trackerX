import 'dart:convert';
import 'dart:async';
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

List<String> buildCountrySuggestions({
  required String query,
  required Iterable<String> countryNames,
  int maxResults = 6,
}) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return [];

  final keys = countryNames.toList();
  final startsWith = keys
      .where((k) => k.toLowerCase().startsWith(normalized))
      .toList()
    ..sort();
  final contains = keys
      .where((k) => !startsWith.contains(k) && k.toLowerCase().contains(normalized))
      .toList()
    ..sort();
  return [...startsWith, ...contains].take(maxResults).toList();
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
  bool _showDetailsPanel = false;
  String? _countriesLoadError;
  int _searchRequestId = 0;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _searchSuggestions = [];
  bool _showSuggestions = false;

  List<dynamic> _countries = [];
  Map<String, List<dynamic>> coordsData = {};
  String _detailsCountryName = "";
  int _detailsWebcamCount = 0;

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

  Future<void> _onPointAnnotationTap(PointAnnotation annotation) async {
    final data = annotation.customData;
    if (data == null) return;
    final Map<dynamic, dynamic> mapData = data;
    final parsedData = Map<String, dynamic>.from(mapData);
    final bool isWebcam = parsedData['isWebcam'] == true;
    if (isWebcam && webcamManager != null) {
      final loadingAnnotation = await webcamManager!.create(
        PointAnnotationOptions(
          geometry: annotation.geometry,
          textField: "⏳",
          textSize: 20,
        ),
      );
      try {
        final lat = annotation.geometry.coordinates[1]!.toDouble();
        final lng = annotation.geometry.coordinates[0]!.toDouble();
        final nearestWebcam = await WebcamService.getWebcam(lat, lng);
        final previewUrl = nearestWebcam?['images']?['current']?['preview'] as String?;
        if (previewUrl != null && previewUrl.isNotEmpty) {
          await WebcamService.prefetchPreviewImage(previewUrl);
        }
      } catch (_) {
        // Non-blocking micro-interaction helper; ignore warm-up failures.
      } finally {
        await webcamManager!.delete(loadingAnnotation);
      }
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AnimatedOpacity(
        duration: const Duration(milliseconds: 280),
        opacity: 1,
        child: GlassmorphismSheet(
          countryData: parsedData,
          location: annotation.geometry,
        ),
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

  Future<void> _searchAndFly(String searchKey) async {
    final coords = coordsData[searchKey];
    if (coords == null || coords.length < 2) {
      _showSnackBar("No coordinates found for \"$searchKey\".");
      return;
    }

    final country = _countries.firstWhere(
      (c) => c['name'].toLowerCase() == searchKey.toLowerCase(),
      orElse: () => null,
    );
    if (country == null || country['code'] == null) {
      _showSnackBar("Country details are still loading. Please try again.");
      return;
    }

    final String countryCode = country['code'].toString().toUpperCase();
    final double lat = (coords[0] as num).toDouble();
    final double lng = (coords[1] as num).toDouble();

    // Non-blocking fly: start camera animation immediately.
    mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: 6,
      ),
      MapAnimationOptions(duration: 2000),
    );

    final int requestId = ++_searchRequestId;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _showSuggestions = false;
        _showDetailsPanel = false;
      });
    }

    try {
      // Parallel fetching during flight:
      // - GraphQL country metadata
      // - Windy country webcams
      // - Windy nearest webcam (used for prefetching preview/stream)
      final results = await Future.wait<dynamic>([
        GraphQLService.fetchCountryByCode(countryCode),
        WebcamService.fetchWebcams(countryCode),
        WebcamService.getWebcam(lat, lng),
      ]);

      if (!mounted || webcamManager == null || requestId != _searchRequestId) return;

      final Map<String, dynamic>? countryMeta = results[0] as Map<String, dynamic>?;
      final List<Webcams> webcams = results[1] as List<Webcams>;
      final Map<String, dynamic>? nearestWebcam = results[2] as Map<String, dynamic>?;

      await webcamManager!.deleteAll();

      final validWebcams = filterWebcamsWithCoordinates(webcams);
      if (validWebcams.isEmpty) {
        _showSnackBar("No active webcams found in this region.");
        return;
      }

      // Pre-fetch preview image and stream metadata while map is moving.
      final String? previewUrl = nearestWebcam?['images']?['current']?['preview'] as String?;
      if (previewUrl != null && previewUrl.isNotEmpty) {
        unawaited(WebcamService.prefetchPreviewImage(previewUrl));
      }

      List<PointAnnotationOptions> webcamMarkers = validWebcams.map((cam) {
        final city = cam.location?.city?.trim();
        final countryFromWebcam = cam.location?.country?.trim();
        final title = (cam.title?.trim().isNotEmpty ?? false)
            ? cam.title!.trim()
            : (city != null && city.isNotEmpty)
                ? "Webcam - $city"
                : (cam.webcamId != null ? "Webcam #${cam.webcamId}" : "Live webcam");
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
            "title": title,
            "name": countryFromWebcam?.isNotEmpty == true
                ? countryFromWebcam
                : (countryMeta?['name'] ?? searchKey),
            "city": (city != null && city.isNotEmpty)
                ? city
                : (nearestWebcam?['location']?['city'] ?? "Not available"),
            "capital": countryMeta?['capital'] ?? "Not available",
            "emoji": countryMeta?['emoji'] ?? "🎥",
            "countryCode": countryCode,
            "isWebcam": true,
          },
        );
      }).toList();

      await webcamManager!.createMulti(webcamMarkers);
      if (mounted && requestId == _searchRequestId) {
        setState(() {
          _detailsCountryName = countryMeta?['name']?.toString() ?? searchKey;
          _detailsWebcamCount = validWebcams.length;
          _showDetailsPanel = true;
        });
      }
    } catch (e) {
      debugPrint("Search and fly load error: $e");
      _showSnackBar("Could not load live webcam data. Please try again.");
    } finally {
      if (mounted && requestId == _searchRequestId) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleSearch(String value) {
    if (value.isEmpty) return;
    
    final searchKey = coordsData.keys.firstWhere(
      (k) => k.toLowerCase() == value.toLowerCase().trim(),
      orElse: () => "",
    );

    if (searchKey.isNotEmpty) {
      _searchAndFly(searchKey);
    } else {
      _showSnackBar("No country found for \"$value\".");
    }
  }

  void _handleSearchInputChanged() {
    final query = _searchController.text;
    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _searchSuggestions = [];
          _showSuggestions = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _searchSuggestions = buildCountrySuggestions(
          query: query,
          countryNames: coordsData.keys,
        );
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
              if (result.hasException) {
                _countriesLoadError ??= result.exception.toString();
              } else if (!result.isLoading) {
                _countriesLoadError = null;
              }

              if (!result.isLoading && !result.hasException && countryManager != null) {
                final countries = result.data?['countries'] ?? [];
                WidgetsBinding.instance.addPostFrameCallback((_) => _addCountryMarkers(countries));
              }
              return const SizedBox.shrink();
            },
          ),

          if (_countriesLoadError != null)
            Positioned(
              top: 120,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
                ),
                child: const Text(
                  "Country metadata could not be loaded. Please check your connection and reload.",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),

          _buildTopSearchBar(),

          if (_isLoading) _buildTopLinearLoader(),
          _buildDetailsPanel(),
        ],
      ),
    );
  }

  Widget _buildTopLinearLoader() {
    return Positioned(
      left: 20,
      right: 20,
      top: 116,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: const SizedBox(
          height: 3,
          child: LinearProgressIndicator(
            backgroundColor: Colors.white12,
            color: Colors.cyanAccent,
            minHeight: 3,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsPanel() {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 24,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        opacity: _showDetailsPanel ? 1 : 0,
        child: IgnorePointer(
          ignoring: !_showDetailsPanel,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF121224).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(Icons.videocam, color: Colors.cyanAccent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "$_detailsWebcamCount live webcams loaded for $_detailsCountryName",
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSearchBar() {
    return Positioned(
      top: 60,
      left: 20,
      right: 20,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
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
      ),
    );
  }
}