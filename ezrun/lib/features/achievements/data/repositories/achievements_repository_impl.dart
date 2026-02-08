import '../../domain/entities/achievement_entity.dart';
import '../../domain/repositories/achievements_repository.dart';
import '../datasources/achievements_data_source.dart';

class AchievementsRepositoryImpl implements AchievementsRepository {
  final AchievementsDataSource _dataSource;

  AchievementsRepositoryImpl(this._dataSource);

  @override
  Future<List<Achievement>> getAchievements(String userId) async {
    final unlockedIds = await _dataSource.fetchUnlockedAchievementIds();

    // Map all achievements and set isUnlocked status
    return AchievementsDataSource.allAchievements.map((achievement) {
      if (unlockedIds.contains(achievement.id)) {
        return achievement.copyWith(
          isUnlocked: true,
          // We could store unlockedAt date in metadata if we change the data structure,
          // for now we just verify ID presence.
          unlockedAt: DateTime.now(), // Placeholder or fetch if available
        );
      }
      return achievement;
    }).toList();
  }

  @override
  Future<List<String>> getUnlockedAchievementIds(String userId) {
    return _dataSource.fetchUnlockedAchievementIds();
  }

  @override
  Future<void> unlockAchievement(String userId, String achievementId) {
    return _dataSource.saveUnlockedAchievement(achievementId);
  }
}
