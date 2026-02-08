import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/territory_entity.dart';
import '../../../run/domain/entities/live_run_state.dart';

/// Repository for territory operations
class TerritoryRepository {
  final SupabaseClient _supabase;

  TerritoryRepository(this._supabase);

  /// Fetch all territories for map display
  Future<List<TerritoryEntity>> fetchAllTerritories() async {
    try {
      final res = await _supabase.rpc('ezrun_get_territories');
      final list = (res as List).cast<Map<String, dynamic>>();
      return list.map(TerritoryEntity.fromMap).toList(growable: false);
    } on PostgrestException catch (e) {
      // Function not found - return empty
      if (e.code == 'PGRST202') return [];
      // Schema mismatch (common when the RPC wasn't migrated yet)
      if (e.code == '42703' ||
          e.message.contains('column u.username does not exist')) {
        throw Exception(
          'Territories RPC is outdated. Apply the Supabase migration: territory_add_run_data.sql',
        );
      }
      // Return type mismatch (e.g. NUMERIC vs DOUBLE PRECISION)
      if (e.code == '42804' ||
          e.message.contains(
            'Returned type numeric does not match expected type double precision',
          )) {
        throw Exception(
          'Territories RPC return types mismatch. Apply the Supabase migration: territory_fix_get_territories_run_distance_cast.sql',
        );
      }
      rethrow;
    }
  }

  /// Fetch current user's territories
  Future<List<TerritoryEntity>> fetchMyTerritories() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final territories = await fetchAllTerritories();
    return territories.where((t) => t.userId == user.id).toList();
  }

  /// Claim territory from a closed loop run
  /// Returns territory ID if successful, null if failed
  Future<String?> claimTerritory({
    required String runId,
    required List<GpsCoordinate> routePoints,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    if (routePoints.length < 4) {
      throw Exception('Not enough points to form a polygon');
    }

    // Convert route points to JSONB format
    // Ensure the polygon is closed (first = last)
    final points = routePoints
        .map((p) => {'lat': p.latitude, 'lng': p.longitude})
        .toList();

    // Close the polygon if not already closed
    final first = points.first;
    final last = points.last;
    if (first['lat'] != last['lat'] || first['lng'] != last['lng']) {
      points.add(first);
    }

    try {
      final result = await _supabase.rpc(
        'ezrun_claim_territory',
        params: {
          'p_user_id': user.id,
          'p_run_id': runId,
          'p_polygon_points': points,
        },
      );

      return result?.toString();
    } on PostgrestException catch (e) {
      if (e.message.contains('too small')) {
        throw Exception('Territory too small. Minimum area is 200 m².');
      }
      rethrow;
    }
  }

  /// Check if a route forms a closed loop (end within 50m of start)
  bool isClosedLoop(List<GpsCoordinate> routePoints) {
    if (routePoints.length < 4) return false;

    final start = routePoints.first;
    final end = routePoints.last;

    // Calculate distance using simple approximation
    const double earthRadius = 6371000; // meters
    final dLat = _toRadians(end.latitude - start.latitude);
    final dLng = _toRadians(end.longitude - start.longitude);

    final a =
        _sin(dLat / 2) * _sin(dLat / 2) +
        _cos(_toRadians(start.latitude)) *
            _cos(_toRadians(end.latitude)) *
            _sin(dLng / 2) *
            _sin(dLng / 2);

    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    final distance = earthRadius * c;

    return distance <= 50; // Within 50 meters
  }

  double _toRadians(double deg) => deg * 3.14159265359 / 180;
  double _sin(double x) => _sinImpl(x);
  double _cos(double x) => _sinImpl(x + 1.5707963267948966);
  double _sqrt(double x) => x >= 0 ? _sqrtImpl(x) : 0;
  double _atan2(double y, double x) {
    if (x > 0) return _atanImpl(y / x);
    if (x < 0 && y >= 0) return _atanImpl(y / x) + 3.14159265359;
    if (x < 0 && y < 0) return _atanImpl(y / x) - 3.14159265359;
    if (x == 0 && y > 0) return 1.5707963267948966;
    if (x == 0 && y < 0) return -1.5707963267948966;
    return 0;
  }

  // Use dart:math for actual implementation
  double _sinImpl(double x) {
    // Taylor series approximation
    x = x % (2 * 3.14159265359);
    double term = x;
    double sum = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      sum += term;
    }
    return sum;
  }

  double _sqrtImpl(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  double _atanImpl(double x) {
    // Simple approximation
    if (x.abs() > 1) {
      return (x > 0 ? 1 : -1) * 1.5707963267948966 - _atanImpl(1 / x);
    }
    double term = x;
    double sum = x;
    for (int i = 1; i <= 15; i++) {
      term *= -x * x;
      sum += term / (2 * i + 1);
    }
    return sum;
  }
}

/// Provider for TerritoryRepository
final territoryRepositoryProvider = Provider<TerritoryRepository>((ref) {
  return TerritoryRepository(Supabase.instance.client);
});

/// Provider for all territories (for map display)
final allTerritoriesProvider = FutureProvider<List<TerritoryEntity>>((
  ref,
) async {
  final repo = ref.watch(territoryRepositoryProvider);
  return repo.fetchAllTerritories();
});

/// Provider for current user's territories
final myTerritoriesProvider = FutureProvider<List<TerritoryEntity>>((
  ref,
) async {
  final repo = ref.watch(territoryRepositoryProvider);
  return repo.fetchMyTerritories();
});

/// Real-time provider for a single territory row (from `ezrun_territories` table).
///
/// Note: This stream returns only DB columns available via PostgREST.
/// The polygon geometry isn't returned here (PostGIS type), but for the bottom
/// sheet we mainly need live area/timestamps.
final territoryRowStreamProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, territoryId) {
      final stream = Supabase.instance.client
          .from('ezrun_territories')
          .stream(primaryKey: ['id'])
          .eq('id', territoryId);

      return stream.map((rows) => rows.isEmpty ? null : rows.first);
    });
