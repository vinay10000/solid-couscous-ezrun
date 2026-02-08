import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

/// Screen that displays level benefits and unlocks
class LevelBenefitsScreen extends ConsumerStatefulWidget {
  final int currentUserLevel;

  const LevelBenefitsScreen({super.key, required this.currentUserLevel});

  @override
  ConsumerState<LevelBenefitsScreen> createState() =>
      _LevelBenefitsScreenState();
}

class _LevelBenefitsScreenState extends ConsumerState<LevelBenefitsScreen> {
  final Random _random = Random();
  late final Map<int, int> _mysteryGifts;

  @override
  void initState() {
    super.initState();
    // Generate random mystery gifts for each level (1-10 coins)
    _mysteryGifts = {};
    for (int level = 1; level <= 100; level++) {
      _mysteryGifts[level] = _random.nextInt(10) + 1; // 1-10 coins
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildLevelBenefitsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.goNamed('profile'),
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Level Benefits',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Unlock features as you level up',
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBenefitsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.md),
      itemCount: 100,
      itemBuilder: (context, index) {
        final level = index + 1;
        final isUnlocked = level <= widget.currentUserLevel;
        return _buildLevelBenefitCard(level, isUnlocked);
      },
    );
  }

  Widget _buildLevelBenefitCard(int level, bool isUnlocked) {
    final unlocks = _getLevelUnlocks(level);
    final mysteryGift = _mysteryGifts[level] ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isUnlocked
            ? AppColors.backgroundSecondary.withOpacity(0.8)
            : AppColors.backgroundSecondary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: isUnlocked
              ? AppColors.primary.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level badge
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: isUnlocked
                  ? LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        Colors.grey.withOpacity(0.3),
                        Colors.grey.withOpacity(0.1),
                      ],
                    ),
              shape: BoxShape.circle,
              border: Border.all(
                color: isUnlocked
                    ? Colors.white.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '$level',
                style: TextStyle(
                  color: isUnlocked ? Colors.white : AppColors.textSecondary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.md),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Level $level',
                      style: TextStyle(
                        color: isUnlocked
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isUnlocked) ...[
                      const SizedBox(width: AppSizes.xs),
                      Icon(
                        Icons.check_circle,
                        color: AppColors.secondary,
                        size: 16,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSizes.xs),

                // Unlocks
                if (unlocks.isNotEmpty) ...[
                  ...unlocks.map(
                    (unlock) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Icon(
                            unlock.icon,
                            color: isUnlocked
                                ? AppColors.primary
                                : AppColors.textSecondary.withOpacity(0.5),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            unlock.description,
                            style: TextStyle(
                              color: isUnlocked
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                ],

                // Mystery gift
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? AppColors.secondary.withOpacity(0.1)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    border: Border.all(
                      color: isUnlocked
                          ? AppColors.secondary.withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.card_giftcard,
                        color: isUnlocked
                            ? AppColors.secondary
                            : AppColors.textSecondary.withOpacity(0.5),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$mysteryGift EZ Coins',
                        style: TextStyle(
                          color: isUnlocked
                              ? AppColors.secondary
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<LevelUnlock> _getLevelUnlocks(int level) {
    final unlocks = <LevelUnlock>[];

    switch (level) {
      case 5:
        unlocks.add(
          LevelUnlock(icon: Icons.map, description: 'Unlock Territory Views'),
        );
        break;
      case 10:
        unlocks.add(LevelUnlock(icon: Icons.feed, description: 'Unlock Feed'));
        break;
      // Add more level unlocks here as needed
      case 15:
        unlocks.add(
          LevelUnlock(
            icon: Icons.leaderboard,
            description: 'Enhanced Leaderboards',
          ),
        );
        break;
      case 20:
        unlocks.add(
          LevelUnlock(
            icon: Icons.emoji_events,
            description: 'Exclusive Achievements',
          ),
        );
        break;
      case 25:
        unlocks.add(
          LevelUnlock(icon: Icons.group, description: 'Club Features'),
        );
        break;
      case 30:
        unlocks.add(
          LevelUnlock(
            icon: Icons.trending_up,
            description: 'Advanced Analytics',
          ),
        );
        break;
    }

    return unlocks;
  }
}

/// Represents a level unlock
class LevelUnlock {
  final IconData icon;
  final String description;

  const LevelUnlock({required this.icon, required this.description});
}
