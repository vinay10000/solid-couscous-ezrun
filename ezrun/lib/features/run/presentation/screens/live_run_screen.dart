import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/providers/live_run_providers.dart';
import '../../domain/entities/live_run_state.dart';
import '../../../territory/data/providers/territory_providers.dart';

/// Live Run Screen - GPS tracking with real-time map and path drawing
class LiveRunScreen extends ConsumerStatefulWidget {
  const LiveRunScreen({super.key});

  @override
  ConsumerState<LiveRunScreen> createState() => _LiveRunScreenState();
}

class _LiveRunScreenState extends ConsumerState<LiveRunScreen> {
  MapboxMap? _mapboxMap;
  bool _isInitializing = true;
  bool _hasLocationPermission = false;
  PolylineAnnotationManager? _polylineManager;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    final notifier = ref.read(liveRunProvider.notifier);
    final hasPermission = await notifier.initialize();

    if (mounted) {
      setState(() {
        _hasLocationPermission = hasPermission;
        _isInitializing = false;
      });
    }
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    // Apply dark style
    await mapboxMap.style.setStyleURI(MapboxStyles.DARK);

    // Hide scale bar, attribution and logo explicitly
    await mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    await mapboxMap.attribution.updateSettings(
      AttributionSettings(enabled: false),
    );
    await mapboxMap.logo.updateSettings(LogoSettings(enabled: false));

    // Setup location puck
    await mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        pulsingColor: AppColors.primary.value,
        pulsingMaxRadius: 30.0,
        showAccuracyRing: true,
        accuracyRingColor: AppColors.primary
            .withAlpha((0.2 * 255).round())
            .value,
      ),
    );

    // Create annotation managers
    _polylineManager = await mapboxMap.annotations
        .createPolylineAnnotationManager();

    // Center on current location
    final state = ref.read(liveRunProvider);
    if (state.currentLocation != null) {
      await _centerOnLocation(state.currentLocation!);
    }
  }

  Future<void> _centerOnLocation(GpsCoordinate location) async {
    if (_mapboxMap == null) return;

    await _mapboxMap!.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(location.longitude, location.latitude),
        ),
        zoom: 16.0,
        bearing: 0,
        pitch: 0,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  Future<void> _updateRouteOnMap(List<GpsCoordinate> routePoints) async {
    if (_polylineManager == null || routePoints.length < 2) return;

    // Clear existing polylines
    await _polylineManager!.deleteAll();

    // Create new polyline
    final coordinates = routePoints
        .map((p) => Position(p.longitude, p.latitude))
        .toList();

    await _polylineManager!.create(
      PolylineAnnotationOptions(
        geometry: LineString(coordinates: coordinates),
        lineColor: AppColors.primary.value,
        lineWidth: 5.0,
        lineOpacity: 0.9,
      ),
    );
  }

  void _startRun() {
    ref.read(liveRunProvider.notifier).startRun();
    HapticFeedback.heavyImpact();
  }

  void _pauseRun() {
    ref.read(liveRunProvider.notifier).pauseRun();
    HapticFeedback.mediumImpact();
  }

  void _resumeRun() {
    ref.read(liveRunProvider.notifier).resumeRun();
    HapticFeedback.mediumImpact();
  }

  Future<void> _stopRun() async {
    HapticFeedback.heavyImpact();

    // Get route points before saving (to check closed loop)
    final routePoints = ref.read(liveRunProvider).routePoints;

    final runId = await ref.read(liveRunProvider.notifier).stopAndSaveRun();

    if (mounted && runId != null) {
      // Check if this run forms a closed loop and claim territory
      final territoryRepo = ref.read(territoryRepositoryProvider);
      final isLoop = territoryRepo.isClosedLoop(routePoints);

      String message = 'Run saved successfully!';

      if (isLoop && routePoints.length >= 4) {
        try {
          await territoryRepo.claimTerritory(
            runId: runId,
            routePoints: routePoints,
          );
          message = '🎉 Territory captured! Run saved.';
          // Refresh territories
          ref.invalidate(allTerritoriesProvider);
        } catch (e) {
          message =
              'Run saved! (Territory: ${e.toString().replaceAll('Exception: ', '')})';
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isLoop ? AppColors.territoryUser : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } else if (mounted) {
      context.pop();
    }
  }

  void _discardRun() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.glassDark,
        title: const Text(
          'Discard Run?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Your run data will not be saved.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(liveRunProvider.notifier).discardRun();
              context.pop();
            },
            child: Text('Discard', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final runState = ref.watch(liveRunProvider);

    // Update route on map when route changes
    ref.listen<LiveRunState>(liveRunProvider, (prev, next) {
      if (next.routePoints.length != (prev?.routePoints.length ?? 0)) {
        _updateRouteOnMap(next.routePoints);
      }
      // Follow user location
      if (next.currentLocation != null && next.isRunning && !next.isPaused) {
        _centerOnLocation(next.currentLocation!);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Map
          if (_isInitializing)
            const Center(child: CircularProgressIndicator())
          else if (!_hasLocationPermission)
            _buildPermissionDenied()
          else
            MapWidget(
              onMapCreated: _onMapCreated,
              styleUri: MapboxStyles.DARK,
              cameraOptions: CameraOptions(
                center: runState.currentLocation != null
                    ? Point(
                        coordinates: Position(
                          runState.currentLocation!.longitude,
                          runState.currentLocation!.latitude,
                        ),
                      )
                    : null,
                zoom: 16.0,
              ),
            ),

          // Top bar with back button
          Positioned(top: 0, left: 0, right: 0, child: _buildTopBar(runState)),

          // Stats overlay
          if (runState.isRunning)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 16,
              right: 16,
              child: _buildStatsOverlay(runState),
            ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(runState),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.location_slash, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text(
              'Location Permission Required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please enable location services to track your run.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(LiveRunState runState) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withAlpha((0.7 * 255).round()),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Back/Close button
          GestureDetector(
            onTap: () {
              if (runState.isRunning) {
                _discardRun();
              } else {
                context.pop();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.glassMedium,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                runState.isRunning ? Icons.close : Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const Spacer(),
          // Title
          Text(
            runState.isRunning
                ? (runState.isPaused ? 'PAUSED' : 'RUNNING')
                : 'START RUN',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balance
        ],
      ),
    );
  }

  Widget _buildStatsOverlay(LiveRunState runState) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.glassMedium,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorderLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                label: 'TIME',
                value: runState.formattedTime,
                icon: Iconsax.timer_1,
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.glassBorderLight,
              ),
              _buildStatItem(
                label: 'DISTANCE',
                value: runState.formattedDistance,
                icon: Iconsax.routing_2,
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.glassBorderLight,
              ),
              _buildStatItem(
                label: 'PACE',
                value: runState.formattedPace,
                icon: Iconsax.speedometer,
                subtitle: '/km',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    String? subtitle,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 2),
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomControls(LiveRunState runState) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
        top: 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withAlpha((0.9 * 255).round()),
            Colors.black.withAlpha((0.5 * 255).round()),
            Colors.transparent,
          ],
        ),
      ),
      child: runState.isRunning
          ? _buildRunningControls(runState)
          : _buildStartButton(),
    );
  }

  Widget _buildStartButton() {
    return Center(
      child: GestureDetector(
        onTap: _startRun,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGlow,
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40),
              Text(
                'START',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRunningControls(LiveRunState runState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Stop button
        GestureDetector(
          onTap: _stopRun,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withAlpha((0.4 * 255).round()),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.stop_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        const SizedBox(width: 32),
        // Pause/Resume button
        GestureDetector(
          onTap: runState.isPaused ? _resumeRun : _pauseRun,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGlow,
                  blurRadius: 25,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Icon(
              runState.isPaused
                  ? Icons.play_arrow_rounded
                  : Icons.pause_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      ],
    );
  }
}
