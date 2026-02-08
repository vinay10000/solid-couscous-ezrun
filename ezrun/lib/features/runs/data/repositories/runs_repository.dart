import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/run_entity.dart';
import '../../../profile/data/repositories/level_repository.dart';

/// Loads the current user's runs.
///
/// Strategy:
/// - Try an RPC first (`ezrun_my_runs`) if it exists.
/// - Fall back to direct table query (`ezrun_runs`) if RPC isn't available.
class RunsRepository {
  final SupabaseClient _supabase;
  final LevelRepository? _levelRepository;
  RunsRepository(this._supabase, [this._levelRepository]);

  /// Realtime stream of the current user's runs.
  ///
  /// This listens directly to `ezrun_runs` so inserts/updates/deletes update UI
  /// instantly (e.g. Profile stats, My Runs list).
  Stream<List<RunEntity>> watchMyRuns() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return Stream.error(Exception('Not authenticated'));
    }

    return _supabase
        .from('ezrun_runs')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(RunEntity.fromMap).toList(growable: false));
  }

  Future<List<RunEntity>> fetchMyRuns({int limit = 30, int offset = 0}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      final res = await _supabase.rpc(
        'ezrun_my_runs',
        params: {'p_limit': limit, 'p_offset': offset},
      );
      final list = (res as List).cast<Map<String, dynamic>>();
      return list.map(RunEntity.fromMap).toList(growable: false);
    } on PostgrestException catch (e) {
      // PostgREST schema cache not refreshed / function not found:
      // Use a fallback query if possible.
      if (e.code == 'PGRST202') {
        return _fetchMyRunsFallback(
          userId: user.id,
          limit: limit,
          offset: offset,
        );
      }
      rethrow;
    }
  }

  Future<List<RunEntity>> _fetchMyRunsFallback({
    required String userId,
    required int limit,
    required int offset,
  }) async {
    final rows = await _supabase
        .from('ezrun_runs')
        .select(
          'id, user_id, distance_km, duration_seconds, avg_pace_sec_per_km, note, status, status_message, is_custom, created_at',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (rows as List)
        .cast<Map<String, dynamic>>()
        .map(RunEntity.fromMap)
        .toList(growable: false);
  }

  Future<void> addCustomRun({
    required double distanceKm,
    required int durationSeconds,
    String? note,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final trimmedNote = note?.trim();
    final avgPace = distanceKm <= 0
        ? null
        : (durationSeconds / distanceKm).round();

    await _supabase.from('ezrun_runs').insert({
      'user_id': user.id,
      'distance_km': distanceKm,
      'duration_seconds': durationSeconds,
      'avg_pace_sec_per_km': avgPace,
      'note': (trimmedNote == null || trimmedNote.isEmpty) ? null : trimmedNote,
      'status': 'custom',
      'status_message': 'Custom run',
      'is_custom': true,
    });

    // Award XP for logging a run
    if (_levelRepository != null) {
      try {
        await _levelRepository.awardRunXp();
      } catch (e) {
        // Silently fail if XP system is not set up yet
      }
    }
  }

  Future<void> updateCustomRun({
    required String runId,
    required double distanceKm,
    required int durationSeconds,
    String? note,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final trimmedNote = note?.trim();
    final avgPace = distanceKm <= 0
        ? null
        : (durationSeconds / distanceKm).round();

    await _supabase
        .from('ezrun_runs')
        .update({
          'distance_km': distanceKm,
          'duration_seconds': durationSeconds,
          'avg_pace_sec_per_km': avgPace,
          'note': (trimmedNote == null || trimmedNote.isEmpty)
              ? null
              : trimmedNote,
          'is_custom': true,
          'status': 'custom',
          'status_message': 'Custom run',
        })
        .eq('id', runId)
        .eq('user_id', user.id);

    // Note: We don't award XP for updates, only for new runs
  }

  Future<void> deleteRun(String runId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _supabase
        .from('ezrun_runs')
        .delete()
        .eq('id', runId)
        .eq('user_id', user.id);
  }
}
