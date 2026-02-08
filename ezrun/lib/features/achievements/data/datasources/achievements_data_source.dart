import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/achievement_entity.dart';

class AchievementsDataSource {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const List<Achievement> allAchievements = [
    Achievement(
      id: 'first-steps',
      title: 'First Steps',
      description: 'Complete your first run.',
      iconAsset: 'assets/images/achievements/first_steps.png',
      type: AchievementType.milestone,
    ),
    Achievement(
      id: 'high-fiver',
      title: 'High Fiver',
      description: 'Run a total of 5 km.',
      iconAsset: 'assets/images/achievements/high_fiver.png',
      type: AchievementType.milestone,
      targetValue: 5000,
    ),
    Achievement(
      id: '10k-warrior',
      title: '10K Warrior',
      description: 'Run a total of 10 km.',
      iconAsset: 'assets/images/achievements/10k_warrior.png',
      type: AchievementType.milestone,
      targetValue: 10000,
    ),
    Achievement(
      id: 'marathon-master',
      title: 'Marathon Master',
      description: 'Run a total of 42 km.',
      iconAsset: 'assets/images/achievements/marathon_master.png',
      type: AchievementType.milestone,
      targetValue: 42000,
    ),
    Achievement(
      id: 'early-bird',
      title: 'Early Bird',
      description: 'Complete a run between 4 AM and 7 AM.',
      iconAsset: 'assets/images/achievements/early_bird.png',
      type: AchievementType.special,
    ),
    Achievement(
      id: 'night-owl',
      title: 'Night Owl',
      description: 'Complete a run between 8 PM and 12 AM.',
      iconAsset: 'assets/images/achievements/night_owl.png',
      type: AchievementType.special,
    ),
    Achievement(
      id: 'half-marathoner',
      title: 'Half Marathoner',
      description: 'Run 21km in total.',
      iconAsset: 'assets/images/achievements/Half_Marathoner.png',
      type: AchievementType.milestone,
      targetValue: 21000,
    ),
    Achievement(
      id: 'weekend-warrior',
      title: 'Weekend Warrior',
      description: 'Log a run on a Saturday and Sunday.',
      iconAsset: 'assets/images/achievements/Weekend_Warrior.png',
      type: AchievementType.streak,
    ),
  ];

  Future<List<String>> fetchUnlockedAchievementIds() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final metadata = user.userMetadata;
    if (metadata != null && metadata.containsKey('achievements')) {
      return List<String>.from(metadata['achievements']);
    }

    return [];
  }

  Future<void> saveUnlockedAchievement(String achievementId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final currentIds = await fetchUnlockedAchievementIds();
    if (!currentIds.contains(achievementId)) {
      final newIds = [...currentIds, achievementId];
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {...user.userMetadata ?? {}, 'achievements': newIds},
        ),
      );
    }
  }
}
