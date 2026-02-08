import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/achievement_entity.dart';
import '../../domain/repositories/achievements_repository.dart';
import '../datasources/achievements_data_source.dart';
import '../repositories/achievements_repository_impl.dart';
import '../../../../core/services/auth_service.dart';

final achievementsRepositoryProvider = Provider<AchievementsRepository>((ref) {
  return AchievementsRepositoryImpl(AchievementsDataSource());
});

final allAchievementsProvider = FutureProvider.autoDispose<List<Achievement>>((
  ref,
) async {
  final repository = ref.watch(achievementsRepositoryProvider);
  final authService = AuthService(); // Or use a provider if available
  final userId = authService.currentUser?.id;

  if (userId == null) {
    return AchievementsDataSource
        .allAchievements; // Return locked list if no user
  }

  return repository.getAchievements(userId);
});
