/// Domain entity representing a claimed territory
class TerritoryEntity {
  final String id;
  final String userId;
  final String? username;
  final String profileColor;
  final String? profilePic;
  final List<List<double>> polygonCoordinates; // [[lng, lat], ...]
  final double areaSqMeters;
  final DateTime createdAt;

  /// Run statistics from the associated run
  final double? runDistanceKm;
  final int? runDurationSeconds;
  final int? runAvgPaceSecPerKm;
  final String? runNote;

  const TerritoryEntity({
    required this.id,
    required this.userId,
    this.username,
    required this.profileColor,
    this.profilePic,
    required this.polygonCoordinates,
    required this.areaSqMeters,
    required this.createdAt,
    this.runDistanceKm,
    this.runDurationSeconds,
    this.runAvgPaceSecPerKm,
    this.runNote,
  });

  /// Area formatted for display
  String get formattedArea {
    if (areaSqMeters < 1000) {
      return '${areaSqMeters.toStringAsFixed(0)} m²';
    } else if (areaSqMeters < 1000000) {
      // m² -> km²
      return '${(areaSqMeters / 1000000).toStringAsFixed(3)} km²';
    } else {
      return '${(areaSqMeters / 1000000).toStringAsFixed(2)} km²';
    }
  }

  /// Run distance formatted for display
  String get formattedRunDistance {
    if (runDistanceKm == null) return '—';
    if (runDistanceKm! < 1) {
      return '${(runDistanceKm! * 1000).toStringAsFixed(0)} m';
    }
    return '${runDistanceKm!.toStringAsFixed(2)} km';
  }

  /// Run duration formatted for display (HH:MM:SS or MM:SS)
  String get formattedRunDuration {
    if (runDurationSeconds == null) return '—';
    final hours = runDurationSeconds! ~/ 3600;
    final minutes = (runDurationSeconds! % 3600) ~/ 60;
    final seconds = runDurationSeconds! % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Run pace formatted for display (MM:SS/km)
  String get formattedRunPace {
    if (runAvgPaceSecPerKm == null || runAvgPaceSecPerKm == 0) return '—';
    final minutes = runAvgPaceSecPerKm! ~/ 60;
    final seconds = runAvgPaceSecPerKm! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}/km';
  }

  String get displayRunTitle {
    final trimmed = runNote?.trim();
    if (trimmed == null || trimmed.isEmpty) return 'Territory run';
    return trimmed;
  }

  factory TerritoryEntity.fromMap(Map<String, dynamic> map) {
    // Parse polygon GeoJSON
    List<List<double>> parsePolygon(dynamic geojson) {
      if (geojson == null) return [];

      try {
        final Map<String, dynamic> geo = geojson is String
            ? {} // Would need JSON.decode
            : geojson as Map<String, dynamic>;

        final coordinates = geo['coordinates'];
        if (coordinates is List && coordinates.isNotEmpty) {
          // GeoJSON polygon: [[[lng, lat], [lng, lat], ...]]
          final ring = coordinates[0] as List;
          return ring
              .map((coord) {
                if (coord is List && coord.length >= 2) {
                  return [
                    (coord[0] as num).toDouble(),
                    (coord[1] as num).toDouble(),
                  ];
                }
                return <double>[0, 0];
              })
              .toList()
              .cast<List<double>>();
        }
      } catch (_) {}
      return [];
    }

    return TerritoryEntity(
      id: (map['id'] ?? '').toString(),
      userId: (map['user_id'] ?? '').toString(),
      username: map['username']?.toString(),
      profileColor: (map['profile_color'] ?? '#00D4FF').toString(),
      profilePic: map['profile_pic']?.toString(),
      polygonCoordinates: parsePolygon(map['polygon_geojson']),
      areaSqMeters: (map['area_sq_meters'] as num?)?.toDouble() ?? 0,
      createdAt: map['created_at'] is String
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now()
          : DateTime.now(),
      // Run statistics from associated run
      runDistanceKm: (map['run_distance_km'] as num?)?.toDouble(),
      runDurationSeconds: (map['run_duration_seconds'] as num?)?.toInt(),
      runAvgPaceSecPerKm: (map['run_avg_pace_sec_per_km'] as num?)?.toInt(),
      runNote: map['run_note']?.toString(),
    );
  }
}
