/// Represents a GPS coordinate point
class GpsCoordinate {
  final double latitude;
  final double longitude;
  final DateTime? timestamp;

  const GpsCoordinate({
    required this.latitude,
    required this.longitude,
    this.timestamp,
  });

  factory GpsCoordinate.fromMap(Map<String, dynamic> map) {
    return GpsCoordinate(
      latitude: (map['lat'] ?? map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['lng'] ?? map['longitude'] ?? 0.0).toDouble(),
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'lat': latitude,
    'lng': longitude,
    if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
  };

  @override
  String toString() => 'GpsCoordinate($latitude, $longitude)';
}

/// State of an active run being tracked
class LiveRunState {
  final bool isRunning;
  final bool isPaused;
  final DateTime? startTime;
  final int elapsedSeconds;
  final double distanceMeters;
  final int? currentPaceSecPerKm;
  final List<GpsCoordinate> routePoints;
  final GpsCoordinate? currentLocation;

  const LiveRunState({
    this.isRunning = false,
    this.isPaused = false,
    this.startTime,
    this.elapsedSeconds = 0,
    this.distanceMeters = 0.0,
    this.currentPaceSecPerKm,
    this.routePoints = const [],
    this.currentLocation,
  });

  double get distanceKm => distanceMeters / 1000.0;

  String get formattedTime {
    final hours = elapsedSeconds ~/ 3600;
    final minutes = (elapsedSeconds % 3600) ~/ 60;
    final seconds = elapsedSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedDistance {
    if (distanceKm < 1) {
      return '${distanceMeters.toStringAsFixed(0)} m';
    }
    return '${distanceKm.toStringAsFixed(2)} km';
  }

  String get formattedPace {
    if (currentPaceSecPerKm == null || currentPaceSecPerKm == 0) {
      return '--:--';
    }
    final minutes = currentPaceSecPerKm! ~/ 60;
    final seconds = currentPaceSecPerKm! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  LiveRunState copyWith({
    bool? isRunning,
    bool? isPaused,
    DateTime? startTime,
    int? elapsedSeconds,
    double? distanceMeters,
    int? currentPaceSecPerKm,
    List<GpsCoordinate>? routePoints,
    GpsCoordinate? currentLocation,
  }) {
    return LiveRunState(
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      startTime: startTime ?? this.startTime,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      currentPaceSecPerKm: currentPaceSecPerKm ?? this.currentPaceSecPerKm,
      routePoints: routePoints ?? this.routePoints,
      currentLocation: currentLocation ?? this.currentLocation,
    );
  }

  static const LiveRunState initial = LiveRunState();
}
