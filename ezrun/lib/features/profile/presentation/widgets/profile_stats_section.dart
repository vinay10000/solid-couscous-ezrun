import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../runs/data/providers/runs_providers.dart';
import 'profile_stat_card.dart';

class ProfileStatsSection extends ConsumerWidget {
  const ProfileStatsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runsStream = ref.watch(myRunsStreamProvider);
    final totalRuns = runsStream.maybeWhen(
      data: (runs) => runs.length,
      orElse: () => 0,
    );
    final totalDistanceKm = runsStream.maybeWhen(
      data: (runs) => runs.fold<double>(0.0, (sum, r) => sum + r.distanceKm),
      orElse: () => 0.0,
    );
    final totalDistanceLabel = '${totalDistanceKm.toStringAsFixed(1)} km';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Stats',
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
          childAspectRatio: 1.0,
          children: [
            ProfileStatCard(
              title: AppStrings.totalRuns,
              value: '$totalRuns',
              icon: Icons.directions_run,
              iconColor: AppColors.primary,
            ),
            ProfileStatCard(
              title: AppStrings.totalDistance,
              value: totalDistanceLabel,
              subtitle: 'all time',
              icon: Icons.straighten,
              iconColor: AppColors.secondary,
            ),
            const ProfileStatCard(
              title: AppStrings.territoryCaptured,
              value: '0',
              subtitle: 'hexagons',
              icon: Icons.map,
              iconColor: AppColors.territoryUser,
            ),
            const ProfileStatCard(
              title: AppStrings.currentStreak,
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
