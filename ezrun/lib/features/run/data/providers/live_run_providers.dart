import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/live_run_state.dart';
import '../../../profile/data/repositories/level_repository.dart';

/// Repository for live run GPS tracking and persistence
class LiveRunRepository {
  final SupabaseClient _supabase;
  final LevelRepository? _levelRepository;

  StreamSubscription<Position>? _positionSubscription;

  LiveRunRepository(this._supabase, [this._levelRepository]);

  /// Check and request location permission
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  /// Start listening to location updates
  Stream<Position> startLocationStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // meters - update every 5 meters
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Calculate distance between two GPS points using Haversine formula
  double calculateDistanceBetween(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  /// Calculate total distance from route points
  double calculateTotalDistance(List<GpsCoordinate> points) {
    if (points.length < 2) return 0;

    double total = 0;
    for (int i = 1; i < points.length; i++) {
      total += calculateDistanceBetween(
        points[i - 1].latitude,
        points[i - 1].longitude,
        points[i].latitude,
        points[i].longitude,
      );
    }
    return total;
  }

  /// Calculate pace in seconds per kilometer
  int? calculatePace(double distanceMeters, int durationSeconds) {
    if (distanceMeters <= 0) return null;
    final distanceKm = distanceMeters / 1000;
    return (durationSeconds / distanceKm).round();
  }

  /// Save completed run to database
  Future<String?> saveRun({
    required double distanceKm,
    required int durationSeconds,
    required List<GpsCoordinate> routePoints,
    String? note,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final avgPace = distanceKm <= 0
        ? null
        : (durationSeconds / distanceKm).round();

    final routeData = routePoints.map((p) => p.toMap()).toList();

    final response = await _supabase
        .from('ezrun_runs')
        .insert({
          'user_id': user.id,
          'distance_km': distanceKm,
          'duration_seconds': durationSeconds,
          'avg_pace_sec_per_km': avgPace,
          'route_coordinates': routeData,
          'note': note,
          'status': 'tracked',
          'status_message': 'GPS tracked run',
          'is_custom': false,
        })
        .select('id')
        .single();

    // Award XP for completing a run
    if (_levelRepository != null) {
      try {
        await _levelRepository!.awardRunXp();
      } catch (_) {
        // Silently fail if XP system is not set up
      }
    }

    return response['id']?.toString();
  }

  void dispose() {
    _positionSubscription?.cancel();
  }
}

/// Provider for LiveRunRepository
final liveRunRepositoryProvider = Provider<LiveRunRepository>((ref) {
  final supabase = Supabase.instance.client;
  // LevelRepository is optional
  LevelRepository? levelRepo;
  try {
    levelRepo = LevelRepository(supabase);
  } catch (_) {}
  return LiveRunRepository(supabase, levelRepo);
});

/// StateNotifier for managing live run state
class LiveRunNotifier extends StateNotifier<LiveRunState> {
  final LiveRunRepository _repository;
  Timer? _timer;
  StreamSubscription<Position>? _locationSubscription;

  LiveRunNotifier(this._repository) : super(LiveRunState.initial);

  /// Initialize location tracking (call before starting run)
  Future<bool> initialize() async {
    final hasPermission = await _repository.checkLocationPermission();
    if (!hasPermission) return false;

    final position = await _repository.getCurrentPosition();
    if (position != null) {
      state = state.copyWith(
        currentLocation: GpsCoordinate(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    }
    return true;
  }

  /// Start the run
  void startRun() {
    if (state.isRunning) return;

    final now = DateTime.now();
    final startLocation = state.currentLocation;

    state = state.copyWith(
      isRunning: true,
      isPaused: false,
      startTime: now,
      elapsedSeconds: 0,
      distanceMeters: 0,
      routePoints: startLocation != null ? [startLocation] : [],
    );

    // Start timer
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!state.isPaused && state.isRunning) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });

    // Start location tracking
    _locationSubscription = _repository.startLocationStream().listen((
      position,
    ) {
      if (!state.isRunning || state.isPaused) return;

      final newPoint = GpsCoordinate(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );

      final updatedPoints = [...state.routePoints, newPoint];
      final newDistance = _repository.calculateTotalDistance(updatedPoints);
      final newPace = _repository.calculatePace(
        newDistance,
        state.elapsedSeconds,
      );

      state = state.copyWith(
        currentLocation: newPoint,
        routePoints: updatedPoints,
        distanceMeters: newDistance,
        currentPaceSecPerKm: newPace,
      );
    });
  }

  /// Pause the run
  void pauseRun() {
    if (!state.isRunning) return;
    state = state.copyWith(isPaused: true);
  }

  /// Resume the run
  void resumeRun() {
    if (!state.isRunning) return;
    state = state.copyWith(isPaused: false);
  }

  /// Stop and save the run
  Future<String?> stopAndSaveRun({String? note}) async {
    if (!state.isRunning) return null;

    _timer?.cancel();
    _locationSubscription?.cancel();

    final runId = await _repository.saveRun(
      distanceKm: state.distanceKm,
      durationSeconds: state.elapsedSeconds,
      routePoints: state.routePoints,
      note: note,
    );

    // Reset state
    state = LiveRunState.initial;

    return runId;
  }

  /// Discard the run without saving
  void discardRun() {
    _timer?.cancel();
    _locationSubscription?.cancel();
    state = LiveRunState.initial;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for LiveRunNotifier
final liveRunProvider = StateNotifierProvider<LiveRunNotifier, LiveRunState>((
  ref,
) {
  final repository = ref.watch(liveRunRepositoryProvider);
  return LiveRunNotifier(repository);
});
