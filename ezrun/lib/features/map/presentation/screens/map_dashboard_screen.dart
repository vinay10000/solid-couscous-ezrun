import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:go_router/go_router.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/state/ui_visibility_providers.dart';
import '../../../runs/presentation/widgets/my_runs_bottom_sheet.dart';
import '../../../territory/data/providers/territory_providers.dart';
import '../../../territory/domain/entities/territory_entity.dart';
import '../../../territory/presentation/widgets/territory_details_bottom_sheet.dart';
import '../widgets/map_profile_pill.dart';
import '../widgets/map_controls.dart';
import '../../../territory/presentation/widgets/captured_territories_bottom_sheet.dart';

/// Map Dashboard Screen - Main map interface with user location and run controls
class MapDashboardScreen extends ConsumerStatefulWidget {
  const MapDashboardScreen({super.key});

  @override
  ConsumerState<MapDashboardScreen> createState() => _MapDashboardScreenState();
}

class _MapDashboardScreenState extends ConsumerState<MapDashboardScreen> {
  MapboxMap? _mapboxMap;
  geo.Position? _currentPosition;
  bool _isLocationPermissionGranted = false;
  bool _isLoadingLocation = true;
  PolygonAnnotationManager? _polygonManager;
  PolylineAnnotationManager? _territoryOutlineManager;
  final Map<String, TerritoryEntity> _territoryByPolygonId = {};
  ProviderSubscription<AsyncValue<List<TerritoryEntity>>>? _territoriesSub;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();

    // Keep the map updated whenever territories refresh/invalidate.
    // In Riverpod v2, use `listenManual` from initState (regular `ref.listen`
    // is only allowed during build).
    _territoriesSub = ref.listenManual<AsyncValue<List<TerritoryEntity>>>(
      allTerritoriesProvider,
      (prev, next) => next.whenData(_drawTerritories),
    );
  }

  @override
  void dispose() {
    _territoriesSub?.close();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    setState(() => _isLoadingLocation = true);
    debugPrint('Starting location initialization');

    try {
      // Check location permission
      debugPrint('Requesting location permission');
      final permission = await Permission.location.request();
      debugPrint('Permission result: ${permission.toString()}');

      if (permission.isGranted) {
        _isLocationPermissionGranted = true;
        debugPrint('Location permission granted, getting position');

        // Get current position
        _currentPosition = await geo.Geolocator.getCurrentPosition(
          desiredAccuracy: geo.LocationAccuracy.high,
        );
        debugPrint(
          'Current position: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}',
        );

        // Location setup will be completed in _onMapCreated when map is ready
        if (_mapboxMap != null) {
          await _setupLocationOnMap();
        } else {
          debugPrint('Map not ready yet, location setup deferred');
        }
      } else {
        debugPrint('Location permission denied');
        _isLocationPermissionGranted = false;
      }
    } catch (e) {
      debugPrint('Error initializing location: $e');
      _isLocationPermissionGranted = false;
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _setupLocationOnMap() async {
    if (_mapboxMap != null &&
        _isLocationPermissionGranted &&
        _currentPosition != null) {
      try {
        debugPrint('Setting up location on map');
        // Enable location services on map
        await _mapboxMap!.location.updateSettings(
          LocationComponentSettings(
            enabled: true,
            pulsingEnabled: true,
            pulsingColor: AppColors.primary.value,
          ),
        );
        debugPrint('Location services enabled on map');

        // Center map on current location
        await _centerOnCurrentLocation();
        debugPrint('Map centered on current location');
      } catch (e) {
        debugPrint('Error setting up location on map: $e');
      }
    } else {
      debugPrint(
        'Cannot setup location: map=${_mapboxMap != null}, permission=${_isLocationPermissionGranted}, position=${_currentPosition != null}',
      );
    }
  }

  Future<void> _centerOnCurrentLocation() async {
    if (_currentPosition != null && _mapboxMap != null) {
      await _mapboxMap!.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(
              _currentPosition!.longitude,
              _currentPosition!.latitude,
            ),
          ),
          zoom: 15.0,
          pitch: 45.0, // tilt for 3D
        ),
        MapAnimationOptions(
          duration: 1500,
        ), // Smooth animation over 1.5 seconds
      );
    }
  }

  Future<void> _zoomBy(double delta) async {
    if (_mapboxMap == null) return;
    final cameraState = await _mapboxMap!.getCameraState();
    await _mapboxMap!.setCamera(CameraOptions(zoom: cameraState.zoom + delta));
  }

  Future<void> _openMyRuns() async {
    ref.read(bottomNavVisibleProvider.notifier).state = false;
    try {
      await MyRunsBottomSheet.show(context);
    } finally {
      ref.read(bottomNavVisibleProvider.notifier).state = true;
    }
  }

  Future<void> _openMyTerritories() async {
    ref.read(bottomNavVisibleProvider.notifier).state = false;
    TerritoryEntity? selected;
    try {
      selected = await CapturedTerritoriesBottomSheet.show(context);
    } finally {
      ref.read(bottomNavVisibleProvider.notifier).state = true;
    }

    if (selected != null && mounted) {
      await _flyToTerritory(selected);
    }
  }

  Future<void> _flyToTerritory(TerritoryEntity territory) async {
    if (_mapboxMap == null || territory.polygonCoordinates.isEmpty) return;

    // Calculate simple centroid (average of points)
    double sumLng = 0;
    double sumLat = 0;
    int count = 0;

    for (final point in territory.polygonCoordinates) {
      if (point.length >= 2) {
        sumLng += point[0];
        sumLat += point[1];
        count++;
      }
    }

    if (count == 0) return;

    final centerLng = sumLng / count;
    final centerLat = sumLat / count;

    await _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(centerLng, centerLat)),
        zoom: 16.5,
        pitch: 50.0,
      ),
      MapAnimationOptions(duration: 1500),
    );
  }

  /// Draw territories on the map
  Future<void> _drawTerritories(List<TerritoryEntity> territories) async {
    if (_polygonManager == null ||
        _territoryOutlineManager == null ||
        _mapboxMap == null)
      return;

    try {
      // Clear existing polygons
      await _polygonManager!.deleteAll();
      await _territoryOutlineManager!.deleteAll();
      _territoryByPolygonId.clear();

      Color boost(Color base) {
        // Make territory colors more vibrant/bright (helps them pop on the basemap).
        final hsv = HSVColor.fromColor(base);
        final boosted = hsv
            .withSaturation((hsv.saturation * 1.25).clamp(0.0, 1.0))
            .withValue((hsv.value * 1.18).clamp(0.0, 1.0));
        return boosted.toColor();
      }

      Color darkOutline(Color base) {
        // A darker outline with a bit of hue retained so it feels “inked” not flat black.
        final hsv = HSVColor.fromColor(base);
        final dark = hsv
            .withSaturation((hsv.saturation * 0.35).clamp(0.0, 1.0))
            .withValue(0.12);
        return dark.toColor();
      }

      // Draw each territory
      for (final territory in territories) {
        if (territory.polygonCoordinates.isEmpty) continue;

        // Parse color from hex string
        final colorHex = territory.profileColor.replaceAll('#', '');
        final colorValue = int.tryParse('FF$colorHex', radix: 16) ?? 0xFF00D4FF;
        final base = Color(colorValue);
        final fill = boost(base);
        final outline = darkOutline(fill);
        final fillColor = fill.value;
        final strokeColor = outline.value;

        // Convert coordinates to Mapbox Position list
        final positions = territory.polygonCoordinates
            .map((coord) => Position(coord[0], coord[1]))
            .toList();

        if (positions.length < 3) continue;

        // Create polygon
        final polygon = await _polygonManager!.create(
          PolygonAnnotationOptions(
            geometry: Polygon(coordinates: [positions]),
            fillColor: fillColor,
            // Higher opacity + boosted color => closer to "bright territories" look.
            fillOpacity: 0.62,
            fillOutlineColor: strokeColor,
          ),
        );
        _territoryByPolygonId[polygon.id] = territory;

        // Draw a thicker, darker outline (annotations’ outline is thin).
        // Using a Polyline annotation gives us width control for far-zoom readability.
        await _territoryOutlineManager!.create(
          PolylineAnnotationOptions(
            geometry: LineString(coordinates: positions),
            lineColor: strokeColor,
            lineWidth: 5.0,
            lineOpacity: 0.95,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error drawing territories: $e');
    }
  }

  Future<void> _openTerritoryDetails(TerritoryEntity territory) async {
    ref.read(bottomNavVisibleProvider.notifier).state = false;
    try {
      await TerritoryDetailsBottomSheet.show(context, territory: territory);
    } finally {
      ref.read(bottomNavVisibleProvider.notifier).state = true;
    }
  }

  void _setupTerritoryTapHandler() {
    _polygonManager?.tapEvents(
      onTap: (annotation) async {
        final territory = _territoryByPolygonId[annotation.id];
        if (territory == null) return;
        if (!mounted) return;
        await _openTerritoryDetails(territory);
      },
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    debugPrint('Map created successfully');
    _mapboxMap = mapboxMap;

    try {
      // NOTE: Mapbox Terms generally require attribution to be visible unless you
      // have the appropriate license/plan. If you just need to avoid UI overlap,
      // consider repositioning instead of disabling.
      //
      // Hide Mapbox logo/caption (bottom-left "Mapbox" text).
      await mapboxMap.logo.updateSettings(LogoSettings(enabled: false));

      // Hide attribution ("i" icon / copyright / legal).
      await mapboxMap.attribution.updateSettings(
        AttributionSettings(enabled: false),
      );

      // Hide the scale bar (e.g., "100m 200m 300m" at the top-left).
      await mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));

      // Disable scale bar
      await mapboxMap.style.setStyleImportConfigProperty(
        'basemap',
        'showScaleBar',
        false,
      );
      debugPrint('Scale bar disabled');

      // Create polygon annotation manager for territories
      _polygonManager = await mapboxMap.annotations
          .createPolygonAnnotationManager();
      debugPrint('Polygon manager created');
      // Create polyline manager for thicker territory outlines
      _territoryOutlineManager = await mapboxMap.annotations
          .createPolylineAnnotationManager();
      debugPrint('Territory outline manager created');

      // Enable tap → territory bottom sheet
      _setupTerritoryTapHandler();

      // Load and draw territories
      await _loadTerritories();

      // Setup location on map if permission is granted and position is available
      await _setupLocationOnMap();
    } catch (e) {
      debugPrint('Error in map creation: $e');
    }
  }

  /// Load territories from backend and draw on map
  Future<void> _loadTerritories() async {
    try {
      final territories = await ref.read(allTerritoriesProvider.future);
      await _drawTerritories(territories);
      debugPrint('Loaded ${territories.length} territories');
    } catch (e) {
      debugPrint('Error loading territories: $e');
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _applyStandardNightTheme() async {
    final map = _mapboxMap;
    if (map == null) return;

    try {
      // Mapbox Standard exposes configurable properties on the `basemap` style import.
      // Darken the basemap so territory colors pop (closer to the reference look).
      await map.style.setStyleImportConfigProperty(
        'basemap',
        'lightPreset',
        'night',
      );
      debugPrint('Applied Mapbox Standard night lightPreset');
    } catch (e) {
      debugPrint('Failed to apply dusk lightPreset or disable scale bar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapbox Map
          MapWidget(
            key: const ValueKey("mapWidget"),
            styleUri: ApiConstants.mapboxStyleStandard,
            mapOptions: MapOptions(
              pixelRatio: MediaQuery.of(context).devicePixelRatio,
            ),
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(
                  ApiConstants.defaultLongitude,
                  ApiConstants.defaultLatitude,
                ),
              ),
              zoom: ApiConstants.defaultZoom,
              pitch: 45.0, // 3D perspective by default
            ),
            onMapCreated: _onMapCreated,
            onStyleLoadedListener: (_) => _applyStandardNightTheme(),
          ),

          // Loading indicator for location
          if (_isLoadingLocation)
            Positioned(
              top: MediaQuery.of(context).padding.top + AppSizes.lg,
              left: AppSizes.lg,
              right: AppSizes.lg,
              child: Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      'Getting your location...',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Notification icon -> opens Notifications Screen (top left)
          if (!_isLoadingLocation)
            Positioned(
              top: MediaQuery.of(context).padding.top + AppSizes.lg,
              left: AppSizes.lg,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  onTap: () => context.pushNamed('notifications'),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.background.withOpacity(0.78),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      border: Border.all(color: Colors.white.withOpacity(0.10)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),

          // Hamburger menu icon -> toggles menu overlay (below notification)
          if (!_isLoadingLocation)
            Positioned(
              top:
                  MediaQuery.of(context).padding.top +
                  AppSizes.lg +
                  56, // Below notification icon
              left: AppSizes.lg, // Same left position as notification
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  onTap: () {
                    setState(() {
                      _isMenuOpen = !_isMenuOpen;
                    });
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.background.withOpacity(0.78),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      border: Border.all(color: Colors.white.withOpacity(0.10)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isMenuOpen ? Icons.close : Icons.menu,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),

          // Current user pill (avatar + name) -> opens Public Profile (top right)
          if (!_isLoadingLocation)
            Positioned(
              top: MediaQuery.of(context).padding.top + AppSizes.lg,
              right: AppSizes.lg, // Position at top right
              child: const MapProfilePill(),
            ),

          // Menu overlay with My runs & My Territories buttons
          if (_isMenuOpen && !_isLoadingLocation)
            Positioned(
              top:
                  MediaQuery.of(context).padding.top +
                  AppSizes.lg +
                  56 +
                  52, // Below the hamburger icon with spacing
              left: AppSizes.lg,
              child: Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // My runs button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        onTap: () {
                          setState(() {
                            _isMenuOpen = false;
                          });
                          _openMyRuns();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.md,
                            vertical: AppSizes.sm,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.directions_run_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: AppSizes.sm),
                              Text(
                                'My runs',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // My Territories button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        onTap: () {
                          setState(() {
                            _isMenuOpen = false;
                          });
                          _openMyTerritories();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.md,
                            vertical: AppSizes.sm,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.flag_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: AppSizes.sm),
                              Text(
                                'My Territories',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Location permission denied message
          if (!_isLoadingLocation && !_isLocationPermissionGranted)
            Positioned(
              top: MediaQuery.of(context).padding.top + AppSizes.lg,
              left: AppSizes.lg,
              right: AppSizes.lg,
              child: Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_off,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(
                        'Location permission required for map features',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await openAppSettings();
                      },
                      child: Text(
                        'Settings',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Map Controls
          MapControls(
            onRecenter: _centerOnCurrentLocation,
            onZoomIn: () => _zoomBy(1),
            onZoomOut: () => _zoomBy(-1),
          ),
        ],
      ),
    );
  }
}
