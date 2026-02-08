import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import 'profile_stat_card.dart';

class PublicProfileStatsSection extends StatelessWidget {
  const PublicProfileStatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Runner Stats',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSizes.md,
          crossAxisSpacing: AppSizes.md,
          childAspectRatio: 0.92,
          children: const [
            ProfileStatCard(
              title: 'Total Runs',
              value: '0',
              icon: Icons.directions_run,
              iconColor: AppColors.primary,
            ),
            ProfileStatCard(
              title: 'Distance',
              value: '0 km',
              subtitle: 'this week',
              icon: Icons.straighten,
              iconColor: AppColors.secondary,
            ),
            ProfileStatCard(
              title: 'Territory',
              value: '0',
              subtitle: 'hexagons',
              icon: Icons.map,
              iconColor: AppColors.territoryUser,
            ),
            ProfileStatCard(
              title: 'Streak',
              value: '0',
              subtitle: 'days',
              icon: Icons.local_fire_department,
              iconColor: AppColors.warning,
            ),
          ],
        ),
      ],
    );
  }
}
