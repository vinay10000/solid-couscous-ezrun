import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/leaderboard_repository.dart';
import '../../domain/entities/leaderboard_entry.dart';

// Repository provider
final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  final supabase = Supabase.instance.client;
  return LeaderboardRepository(supabase);
});

// Global leaderboard stream provider
final globalLeaderboardProvider = StreamProvider<List<LeaderboardEntry>>((ref) {
  final repository = ref.watch(leaderboardRepositoryProvider);
  return repository.watchGlobalLeaderboard();
});

// Current user rank provider
final currentUserRankProvider = FutureProvider<int>((ref) {
  final repository = ref.watch(leaderboardRepositoryProvider);
  return repository.getCurrentUserRank();
});

// User ranking details provider (for showing user's position with nearby users)
final userRankingDetailsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final repository = ref.watch(leaderboardRepositoryProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    return Future.value({
      'userRank': 0,
      'userEntry': null,
      'nearbyEntries': <LeaderboardEntry>[],
    });
  }
  return repository.fetchUserRanking(user.id);
});

// Top leaderboard entries provider (for initial load)
final topLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) {
  final repository = ref.watch(leaderboardRepositoryProvider);
  return repository.fetchTopLeaderboard(limit: 100);
});
