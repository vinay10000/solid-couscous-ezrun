import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/leaderboard_entry.dart';

class TopThreePodium extends StatelessWidget {
  final List<LeaderboardEntry> topThree;

  final Function(String userId)? onUserTap;

  const TopThreePodium({super.key, required this.topThree, this.onUserTap});

  @override
  Widget build(BuildContext context) {
    if (topThree.isEmpty) return const SizedBox.shrink();

    // Sort just in case, though usually it comes sorted.
    // We want to arrange them visually: 2 - 1 - 3
    // But index 0 is rank 1, index 1 is rank 2, index 2 is rank 3.
    final first = topThree.isNotEmpty ? topThree[0] : null;
    final second = topThree.length > 1 ? topThree[1] : null;
    final third = topThree.length > 2 ? topThree[2] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.lg,
        horizontal: AppSizes.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Second Place (Left)
          if (second != null)
            Expanded(
              child: _PodiumItem(
                entry: second,
                color: const Color(0xFFC0C0C0), // Silver
                podiumHeight: 120,
                avatarSize: 56,
                onTap: () => onUserTap?.call(second.userId),
              ),
            )
          else
            const Spacer(),

          // First Place (Center, larger)
          if (first != null)
            Expanded(
              flex:
                  3, // Give rank 1 a bit more width if needed, or keeping it balanced
              child: _PodiumItem(
                entry: first,
                color: const Color(0xFFFFD700), // Gold
                podiumHeight: 155,
                avatarSize: 74,
                isFirst: true,
                onTap: () => onUserTap?.call(first.userId),
              ),
            )
          else
            const Spacer(),

          // Third Place (Right)
          if (third != null)
            Expanded(
              child: _PodiumItem(
                entry: third,
                color: const Color(0xFFCD7F32), // Bronze
                podiumHeight: 120,
                avatarSize: 56,
                onTap: () => onUserTap?.call(third.userId),
              ),
            )
          else
            const Spacer(),
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final LeaderboardEntry entry;
  final Color color;
  final double podiumHeight;
  final double avatarSize;
  final bool isFirst;
  final VoidCallback? onTap;

  const _PodiumItem({
    required this.entry,
    required this.color,
    required this.podiumHeight,
    required this.avatarSize,
    this.isFirst = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Avatar
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: UserAvatar(
              imageUrl: entry.profilePic,
              username: entry.username,
              profileColor: entry.profileColor,
              radius: avatarSize / 2,
            ),
          ),

          const SizedBox(height: 8),

          // Username
          Text(
            entry.username,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: isFirst ? 16 : 14,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // Points Badge (XP logic unchanged)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.glassLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.glassBorderSubtle),
            ),
            child: Text(
              '${entry.totalXp} XP',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Podium block with rank number (2 - 1 - 3)
          Container(
            height: podiumHeight,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.glassLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.radiusLg),
                topRight: Radius.circular(AppSizes.radiusLg),
              ),
              border: Border.all(color: AppColors.glassBorderSubtle),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusLg),
                  topRight: Radius.circular(AppSizes.radiusLg),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withOpacity(0.18), color.withOpacity(0.02)],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${entry.rank}',
                style: TextStyle(
                  color: AppColors.textPrimary.withOpacity(0.85),
                  fontWeight: FontWeight.w900,
                  fontSize: isFirst ? 34 : 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
