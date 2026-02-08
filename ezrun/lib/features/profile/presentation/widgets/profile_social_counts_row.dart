import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../data/providers/profile_social_providers.dart';

class ProfileSocialCountsRow extends ConsumerWidget {
  final String userId;

  const ProfileSocialCountsRow({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCounts = ref.watch(profileSocialCountsProvider(userId));

    return asyncCounts.when(
      data: (counts) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CountItem(
              label: 'Posts',
              value: counts.posts.toString(),
              onTap: null,
            ),
            const _Divider(),
            _CountItem(
              label: 'Followers',
              value: counts.followers.toString(),
              onTap: () => context.push('/followers/$userId'),
            ),
            const _Divider(),
            _CountItem(
              label: 'Following',
              value: counts.following.toString(),
              onTap: () => context.push('/following/$userId'),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.sm),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _CountItem extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _CountItem({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: child,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withOpacity(0.08),
    );
  }
}
