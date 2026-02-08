/// Domain entity representing a completed (or pending) run.
///
/// This is intentionally UI-friendly and resilient to schema changes, because
/// the exact DB schema for runs may evolve.
class RunEntity {
  final String id;
  final String userId;

  /// Total distance in kilometers.
  final double distanceKm;

  /// Total duration in seconds.
  final int durationSeconds;

  /// Average pace in seconds per kilometer (optional).
  final int? avgPaceSecPerKm;

  /// Status (e.g. "in_terra", "pending", "rejected") - optional.
  final String? status;

  /// Status message (e.g. "Treadmill run can't be added") - optional.
  final String? statusMessage;

  /// Optional free-form note (for custom/manual runs).
  final String? note;

  /// True if this run was created manually by the user (custom run).
  final bool isCustom;

  /// GPS route coordinates as list of {lat, lng} maps.
  final List<Map<String, double>> routeCoordinates;

  final DateTime createdAt;

  const RunEntity({
    required this.id,
    required this.userId,
    required this.distanceKm,
    required this.durationSeconds,
    required this.avgPaceSecPerKm,
    required this.status,
    required this.statusMessage,
    required this.note,
    required this.isCustom,
    required this.createdAt,
    this.routeCoordinates = const [],
  });

  factory RunEntity.fromMap(Map<String, dynamic> map) {
    DateTime parseCreatedAt(dynamic v) {
      if (v is DateTime) return v;
      if (v is String) {
        try {
          return DateTime.parse(v);
        } catch (_) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    List<Map<String, double>> parseRouteCoordinates(dynamic v) {
      if (v == null) return [];
      if (v is List) {
        return v
            .map((item) {
              if (item is Map) {
                return {
                  'lat': (item['lat'] ?? item['latitude'] ?? 0.0).toDouble(),
                  'lng': (item['lng'] ?? item['longitude'] ?? 0.0).toDouble(),
                };
              }
              return <String, double>{};
            })
            .where((m) => m.isNotEmpty)
            .toList()
            .cast<Map<String, double>>();
      }
      return [];
    }

    // Common field names we might use in Supabase:
    // distance_km | distanceKm | distance
    // duration_seconds | durationSeconds | duration
    // avg_pace_sec_per_km | avgPaceSecPerKm | avg_pace
    final id = (map['id'] ?? '').toString();
    final userId = (map['user_id'] ?? map['userId'] ?? '').toString();

    final distanceKm = parseDouble(
      map['distance_km'] ?? map['distanceKm'] ?? map['distance'],
    );
    final durationSeconds = parseInt(
      map['duration_seconds'] ?? map['durationSeconds'] ?? map['duration'],
    );
    final avgPaceSecPerKmRaw =
        map['avg_pace_sec_per_km'] ?? map['avgPaceSecPerKm'] ?? map['avg_pace'];
    final avgPaceSecPerKm = avgPaceSecPerKmRaw == null
        ? null
        : parseInt(avgPaceSecPerKmRaw);

    final status = map['status']?.toString();
    final statusMessage = (map['status_message'] ?? map['statusMessage'])
        ?.toString();
    final note = (map['note'] ?? map['run_note'])?.toString();
    final isCustomRaw = map['is_custom'] ?? map['isCustom'];
    final isCustom = isCustomRaw is bool ? isCustomRaw : false;

    final routeCoordinates = parseRouteCoordinates(
      map['route_coordinates'] ?? map['routeCoordinates'],
    );

    final createdAt = parseCreatedAt(map['created_at'] ?? map['createdAt']);

    return RunEntity(
      id: id,
      userId: userId,
      distanceKm: distanceKm,
      durationSeconds: durationSeconds,
      avgPaceSecPerKm: avgPaceSecPerKm,
      status: status,
      statusMessage: statusMessage,
      note: note,
      isCustom: isCustom,
      routeCoordinates: routeCoordinates,
      createdAt: createdAt,
    );
  }
}
