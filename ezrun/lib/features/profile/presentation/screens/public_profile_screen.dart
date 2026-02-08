import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../data/providers/profile_social_providers.dart';
import '../widgets/profile_social_counts_row.dart';
import '../widgets/public_profile_stats_section.dart';

final _publicUserProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, userId) async {
      final supabase = Supabase.instance.client;
      final rows = await supabase
          .from('users')
          .select('id, name, email, profile_pic')
          .eq('id', userId)
          .limit(1);
      final list = (rows as List).cast<Map<String, dynamic>>();
      return list.isEmpty ? null : list.first;
    });

class PublicProfileScreen extends ConsumerWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  void _onProfileImageTap(
    BuildContext context, {
    required String username,
    required String? profileImageUrl,
  }) {
    final queryParams = <String, String>{
      if (profileImageUrl != null) 'imageUrl': profileImageUrl,
      'username': username,
      // Intentionally no canDelete flag for public profiles.
    };

    context.push(
      Uri(
        path: '/profile-image-viewer',
        queryParameters: queryParams,
      ).toString(),
    );
  }

  Future<void> _toggleFollow(
    BuildContext context,
    WidgetRef ref, {
    required bool isFollowing,
    required String userId,
  }) async {
    final repo = ref.read(profileSocialRepositoryProvider);
    try {
      if (isFollowing) {
        await repo.unfollow(userId);
      } else {
        await repo.follow(userId);
      }
      final me = Supabase.instance.client.auth.currentUser;
      ref.invalidate(isFollowingProvider(userId));
      ref.invalidate(hasPendingFollowRequestProvider(userId));
      ref.invalidate(profileSocialCountsProvider(userId));
      if (me != null) {
        ref.invalidate(profileSocialCountsProvider(me.id));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = Supabase.instance.client.auth.currentUser;
    final isMe = me?.id == userId;
    final userAsync = ref.watch(_publicUserProvider(userId));
    final followingAsync = ref.watch(isFollowingProvider(userId));
    final pendingAsync = ref.watch(hasPendingFollowRequestProvider(userId));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          'Profile',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: userAsync.when(
          data: (user) {
            if (user == null) {
              return const Center(
                child: Text(
                  'User not found',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }

            final name =
                (user['name'] as String?) ??
                ((user['email'] as String?)?.split('@').first ?? 'Runner');
            final profilePic = user['profile_pic'] as String?;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.lg,
                AppSizes.lg,
                AppSizes.lg,
                AppSizes.lg + AppSizes.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Avatar(
                    url: profilePic,
                    onTap: () => _onProfileImageTap(
                      context,
                      username: name,
                      profileImageUrl: profilePic,
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!isMe) ...[
                    const SizedBox(height: AppSizes.md),
                    followingAsync.when(
                      data: (isFollowing) => pendingAsync.when(
                        data: (isPending) => _FollowButton(
                          isFollowing: isFollowing,
                          isPending: isPending,
                          onTap: isPending && !isFollowing
                              ? null
                              : () => _toggleFollow(
                                  context,
                                  ref,
                                  isFollowing: isFollowing,
                                  userId: userId,
                                ),
                        ),
                        loading: () => const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        error: (_, __) => _FollowButton(
                          isFollowing: isFollowing,
                          isPending: false,
                          onTap: () => _toggleFollow(
                            context,
                            ref,
                            isFollowing: isFollowing,
                            userId: userId,
                          ),
                        ),
                      ),
                      loading: () => const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                  const SizedBox(height: AppSizes.md),
                  ProfileSocialCountsRow(userId: userId),
                  const SizedBox(height: AppSizes.xxl),
                  const PublicProfileStatsSection(),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Text(
                e.toString(),
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final bool isPending;
  final VoidCallback? onTap;

  const _FollowButton({
    required this.isFollowing,
    required this.isPending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: isFollowing
              ? AppColors.textPrimary
              : AppColors.primary,
          side: BorderSide(
            color: isFollowing
                ? Colors.white.withOpacity(0.14)
                : AppColors.primary,
          ),
          backgroundColor: isFollowing
              ? AppColors.backgroundSecondary
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: Text(
          isFollowing ? 'Following' : (isPending ? 'Requested' : 'Follow'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final VoidCallback onTap;
  const _Avatar({required this.url, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.trim().isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'profile_image_$url',
        child: Container(
          width: AppSizes.avatarXl,
          height: AppSizes.avatarXl,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
            boxShadow: const [
              BoxShadow(
                color: AppColors.primaryGlow,
                blurRadius: 18,
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipOval(
            child: hasUrl
                ? CachedNetworkImage(
                    imageUrl: url!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.person, color: Colors.white, size: 48),
                  )
                : const Icon(Icons.person, color: Colors.white, size: 48),
          ),
        ),
      ),
    );
  }
}
