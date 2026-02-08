import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_level.dart';
import '../repositories/level_repository.dart';

final levelRepositoryProvider = Provider<LevelRepository>((ref) {
  return LevelRepository(Supabase.instance.client);
});

/// Provider for the current user's level information.
final userLevelProvider = FutureProvider.autoDispose<UserLevel>((ref) async {
  final repo = ref.watch(levelRepositoryProvider);
  return repo.fetchUserLevel();
});

/// Provider for a specific user's level (for public profiles, leaderboards, etc.)
final userLevelByIdProvider = FutureProvider.autoDispose
    .family<UserLevel, String>((ref, userId) async {
      final repo = ref.watch(levelRepositoryProvider);
      return repo.fetchUserLevelById(userId);
    });
