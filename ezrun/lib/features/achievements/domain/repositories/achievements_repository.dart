import '../entities/achievement_entity.dart';

abstract class AchievementsRepository {
  Future<List<Achievement>> getAchievements(String userId);
  Future<void> unlockAchievement(String userId, String achievementId);
  Future<List<String>> getUnlockedAchievementIds(String userId);
}
