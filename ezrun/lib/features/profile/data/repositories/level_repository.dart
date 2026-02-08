import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_level.dart';

/// Repository for managing user XP and level progression.
class LevelRepository {
  final SupabaseClient _supabase;
  LevelRepository(this._supabase);

  /// Fetch the current user's level information.
  Future<UserLevel> fetchUserLevel() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      // Try fetching from users table
      final data = await _supabase
          .from('users')
          .select('total_xp')
          .eq('id', user.id)
          .single();

      return UserLevel.fromMap(data);
    } catch (e) {
      // If column doesn't exist yet, return initial level
      return UserLevel.initial();
    }
  }

  /// Add XP to the current user's account.
  /// Returns the updated level information.
  Future<UserLevel> addXp(int xpToAdd) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    if (xpToAdd <= 0) {
      return await fetchUserLevel();
    }

    try {
      // Use PostgreSQL function for atomic XP update
      final result = await _supabase.rpc(
        'ezrun_add_user_xp',
        params: {'p_user_id': user.id, 'p_xp_amount': xpToAdd},
      );

      if (result is Map) {
        return UserLevel.fromMap(result.cast<String, dynamic>());
      } else if (result is List && result.isNotEmpty) {
        return UserLevel.fromMap((result.first as Map).cast<String, dynamic>());
      }

      // Fallback: fetch the updated value
      return await fetchUserLevel();
    } on PostgrestException catch (e) {
      // If RPC doesn't exist, fall back to direct update
      if (e.code == 'PGRST202' || e.code == '42883') {
        return await _addXpFallback(xpToAdd);
      }
      rethrow;
    }
  }

  /// Fallback method if RPC is not available.
  Future<UserLevel> _addXpFallback(int xpToAdd) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // First, get current XP
    final current = await fetchUserLevel();
    final newTotalXp = current.totalXp + xpToAdd;

    // Update in database
    await _supabase
        .from('users')
        .update({'total_xp': newTotalXp})
        .eq('id', user.id);

    return UserLevel.fromTotalXp(newTotalXp);
  }

  /// Award XP for completing a run.
  Future<UserLevel> awardRunXp() async {
    return await addXp(LevelSystem.xpPerRun);
  }

  /// Get user level for a specific user (for leaderboard, etc.)
  Future<UserLevel> fetchUserLevelById(String userId) async {
    try {
      final data = await _supabase
          .from('users')
          .select('total_xp')
          .eq('id', userId)
          .single();

      return UserLevel.fromMap(data);
    } catch (e) {
      return UserLevel.initial();
    }
  }

  /// Reset user XP (for testing/admin purposes).
  Future<void> resetXp() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _supabase.from('users').update({'total_xp': 0}).eq('id', user.id);
  }
}
