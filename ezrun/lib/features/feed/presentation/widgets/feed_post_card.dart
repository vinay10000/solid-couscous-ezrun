import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../data/providers/feed_providers.dart';
import '../../domain/entities/feed_post.dart';
import '../../../profile/data/providers/profile_social_providers.dart';

class FeedPostCard extends ConsumerWidget {
  final FeedPost post;
  final FeedTab tab;

  const FeedPostCard({super.key, required this.post, required this.tab});

  Future<void> _toggleLike(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(feedRepositoryProvider);
    try {
      if (post.isLiked) {
        await repo.unlikePost(post.postId);
      } else {
        await repo.likePost(post.postId);
      }
      ref.invalidate(feedPostsProvider(tab));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _openComments(BuildContext context) {
    context.push(
      '/post/${post.postId}/comments?authorName=${Uri.encodeComponent(post.username)}',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasImage = post.imageUrl != null && post.imageUrl!.trim().isNotEmpty;
    final me = Supabase.instance.client.auth.currentUser;
    final isMe = me?.id == post.userId;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSizes.lg,
        0,
        AppSizes.lg,
        AppSizes.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              userId: post.userId,
              username: post.username,
              profilePic: post.profilePic,
              createdAt: post.createdAt,
              showFollowButton: tab == FeedTab.explore && !isMe,
            ),
            if (hasImage)
              AspectRatio(
                aspectRatio: 1,
                child: CachedNetworkImage(
                  imageUrl: post.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, _) => Container(
                    color: AppColors.background,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  errorWidget: (context, _, __) => Container(
                    color: AppColors.background,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.lg,
                  AppSizes.lg,
                  AppSizes.lg,
                  AppSizes.xl,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.06),
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  (post.caption ?? '').trim().isEmpty
                      ? 'Text post'
                      : post.caption!.trim(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _toggleLike(context, ref),
                        icon: Icon(
                          post.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: post.isLiked
                              ? AppColors.error
                              : AppColors.textPrimary,
                        ),
                        tooltip: post.isLiked ? 'Unlike' : 'Like',
                      ),
                      IconButton(
                        onPressed: () => _openComments(context),
                        icon: const Icon(
                          Icons.mode_comment_outlined,
                          color: AppColors.textPrimary,
                        ),
                        tooltip: 'Comments',
                      ),
                      const Spacer(),
                      Text(
                        '${post.likeCount} likes',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (hasImage && (post.caption ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      post.caption!.trim(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    '${post.commentCount} comments',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final String userId;
  final String username;
  final String? profilePic;
  final DateTime createdAt;
  final bool showFollowButton;

  const _Header({
    required this.userId,
    required this.username,
    required this.profilePic,
    required this.createdAt,
    required this.showFollowButton,
  });

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  Future<void> _toggleFollow(
    BuildContext context,
    WidgetRef ref,
    bool isFollowing,
  ) async {
    final repo = ref.read(profileSocialRepositoryProvider);
    try {
      if (isFollowing) {
        await repo.unfollow(userId);
      } else {
        await repo.follow(userId);
      }
      ref.invalidate(isFollowingProvider(userId));
      ref.invalidate(hasPendingFollowRequestProvider(userId));
      ref.invalidate(profileSocialCountsProvider(userId));
      ref.invalidate(feedPostsProvider(FeedTab.following));
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
    final followAsync = showFollowButton
        ? ref.watch(isFollowingProvider(userId))
        : null;
    final pendingAsync = showFollowButton
        ? ref.watch(hasPendingFollowRequestProvider(userId))
        : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.md,
        AppSizes.md,
        AppSizes.sm,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.push('/u/$userId'),
            child: _Avatar(url: profilePic),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/u/$userId'),
              child: Text(
                username,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          if (showFollowButton)
            followAsync!.when(
              data: (isFollowing) => pendingAsync!.when(
                data: (isPending) {
                  final disabled = isPending && !isFollowing;
                  return SizedBox(
                    height: 28,
                    child: OutlinedButton(
                      onPressed: disabled
                          ? null
                          : () => _toggleFollow(context, ref, isFollowing),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        foregroundColor: isFollowing
                            ? AppColors.textPrimary
                            : (disabled
                                  ? AppColors.textSecondary.withOpacity(0.7)
                                  : AppColors.primary),
                        side: BorderSide(
                          color: isFollowing
                              ? Colors.white.withOpacity(0.14)
                              : (disabled
                                    ? Colors.white.withOpacity(0.10)
                                    : AppColors.primary),
                        ),
                        backgroundColor: isFollowing
                            ? AppColors.backgroundSecondary
                            : Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusLg,
                          ),
                        ),
                      ),
                      child: Text(
                        isFollowing
                            ? 'Following'
                            : (isPending ? 'Requested' : 'Follow'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
                error: (_, __) => SizedBox(
                  height: 28,
                  child: OutlinedButton(
                    onPressed: () => _toggleFollow(context, ref, isFollowing),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
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
                    ),
                    child: Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              loading: () => const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            )
          else
            const SizedBox.shrink(),
          Text(
            _timeAgo(createdAt),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  const _Avatar({required this.url});

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.trim().isNotEmpty;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
      ),
      child: ClipOval(
        child: hasUrl
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.person, color: Colors.white, size: 18),
              )
            : const Icon(Icons.person, color: Colors.white, size: 18),
      ),
    );
  }
}
