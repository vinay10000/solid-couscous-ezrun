import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/leaderboard_entry.dart';

/// Repository for managing leaderboard data with real-time updates.
///
/// Provides methods to fetch global rankings and user-specific ranking data.
class LeaderboardRepository {
  final SupabaseClient _supabase;

  LeaderboardRepository(this._supabase);

  /// Real-time stream of global leaderboard rankings.
  ///
  /// Returns top 100 users ordered by total XP descending.
  /// Updates automatically when XP changes occur.
  Stream<List<LeaderboardEntry>> watchGlobalLeaderboard() {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .order('total_xp', ascending: false)
        .limit(100)
        .map(_mapUsersToLeaderboardEntries);
  }

  /// Fetch current user's ranking position.
  ///
  /// Returns the user's position in the global leaderboard along with nearby users.
  Future<Map<String, dynamic>> fetchUserRanking(String userId) async {
    try {
      // Get the user's total XP
      final userData = await _supabase
          .from('users')
          .select('id, name, profile_pic, profile_color, total_xp')
          .eq('id', userId)
          .single();

      final userXp = (userData['total_xp'] as num?)?.toInt() ?? 0;

      // Count how many users have more XP than this user
      final usersAbove = await _supabase
          .from('users')
          .select('id')
          .gt('total_xp', userXp)
          .count();

      // Count users with exactly the same XP but higher ID (for tie-breaking)
      final usersWithSameXp = await _supabase
          .from('users')
          .select('id')
          .eq('total_xp', userXp)
          .lt('id', userId)
          .count();

      final rank = usersAbove.count + usersWithSameXp.count + 1;

      // Get a few users around the current user's position
      final nearbyUsers = await _supabase
          .from('users')
          .select('id, name, profile_pic, profile_color, total_xp')
          .order('total_xp', ascending: false)
          .range((rank - 3).clamp(0, 97), (rank + 2).clamp(0, 99));

      final nearbyEntries = _mapUsersToLeaderboardEntries(nearbyUsers as List);

      return {
        'userRank': rank,
        'userEntry': LeaderboardEntry.fromMap(
          userData,
          rank: rank,
          isCurrentUser: true,
        ),
        'nearbyEntries': nearbyEntries,
      };
    } catch (e) {
      // Return default data if something goes wrong
      return {
        'userRank': 0,
        'userEntry': null,
        'nearbyEntries': <LeaderboardEntry>[],
      };
    }
  }

  /// Fetch top leaderboard entries (non-streaming).
  ///
  /// Useful for initial load or when real-time isn't needed.
  Future<List<LeaderboardEntry>> fetchTopLeaderboard({int limit = 50}) async {
    try {
      final users = await _supabase
          .from('users')
          .select('id, name, profile_pic, profile_color, total_xp')
          .order('total_xp', ascending: false)
          .limit(limit);

      return _mapUsersToLeaderboardEntries(users as List);
    } catch (e) {
      return [];
    }
  }

  /// Convert raw user data to LeaderboardEntry objects with proper ranking.
  List<LeaderboardEntry> _mapUsersToLeaderboardEntries(List users) {
    final entries = <LeaderboardEntry>[];
    for (var i = 0; i < users.length; i++) {
      final user = users[i] as Map<String, dynamic>;
      entries.add(LeaderboardEntry.fromMap(user, rank: i + 1));
    }
    return entries;
  }

  /// Get current user's leaderboard position for quick display.
  Future<int> getCurrentUserRank() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0;

    final result = await fetchUserRanking(user.id);
    return result['userRank'] as int? ?? 0;
  }
}
