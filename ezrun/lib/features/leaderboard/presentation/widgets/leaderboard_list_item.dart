import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/liquid_glass.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/leaderboard_entry.dart';

/// A single leaderboard entry item with ranking, user info, and XP display
class LeaderboardListItem extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isTopThree;
  final VoidCallback? onTap;

  const LeaderboardListItem({
    super.key,
    required this.entry,
    this.isTopThree = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rankText = entry.rank < 10 ? '0${entry.rank}' : '${entry.rank}';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      child: LiquidGlass(
        onTap: onTap,
        backgroundColor: entry.isCurrentUser
            ? AppColors.primary.withOpacity(0.10)
            : AppColors.glassLight,
        borderColor: entry.isCurrentUser
            ? AppColors.primary.withOpacity(0.3)
            : AppColors.glassBorderLight,
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 34,
              child: Text(
                rankText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: entry.isCurrentUser
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(width: AppSizes.md),

            // Profile picture or default avatar
            _buildProfileAvatar(),

            const SizedBox(width: AppSizes.md),

            // User info section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Username
                  Text(
                    entry.username,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: entry.isCurrentUser
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: entry.isCurrentUser
                          ? AppColors.textPrimary
                          : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Points pill (XP logic unchanged)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.glassMedium,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      border: Border.all(color: AppColors.glassBorderSubtle),
                    ),
                    child: Text(
                      '${entry.totalXp} XP',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Trailing slot (reference UI uses movement arrows)
            const SizedBox(width: 8),
            if (isTopThree)
              Icon(Icons.emoji_events, color: _getRankColor(), size: 20)
            else
              const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return UserAvatar(
      imageUrl: entry.profilePic,
      username: entry.username,
      profileColor: entry.profileColor,
      radius: 18,
      borderSize: 1.5,
      borderColor: entry.isCurrentUser
          ? AppColors.primary.withOpacity(0.5)
          : AppColors.glassBorderLight.withOpacity(0.5),
    );
  }

  Color _getRankColor() {
    switch (entry.rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.primary;
    }
  }
}
