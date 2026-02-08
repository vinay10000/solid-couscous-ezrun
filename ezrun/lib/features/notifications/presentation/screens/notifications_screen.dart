import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/widgets/app_glass_card.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../data/providers/notifications_providers.dart';
import '../../domain/entities/app_notification.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final Set<String> _busyRequestIds = <String>{};

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  Future<void> _acceptFollowRequest(AppNotification n) async {
    final requestId = n.followRequestId;
    if (requestId == null) return;
    if (_busyRequestIds.contains(requestId)) return;

    setState(() => _busyRequestIds.add(requestId));
    final repo = ref.read(notificationsRepositoryProvider);
    try {
      await repo.acceptFollowRequest(
        requestId: requestId,
        requesterId: n.actorUserId,
      );
      ref.invalidate(notificationsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: context.semanticColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyRequestIds.remove(requestId));
      }
    }
  }

  Future<void> _denyFollowRequest(AppNotification n) async {
    final requestId = n.followRequestId;
    if (requestId == null) return;
    if (_busyRequestIds.contains(requestId)) return;

    setState(() => _busyRequestIds.add(requestId));
    final repo = ref.read(notificationsRepositoryProvider);
    try {
      await repo.denyFollowRequest(requestId: requestId);
      ref.invalidate(notificationsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: context.semanticColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busyRequestIds.remove(requestId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final asyncNotifs = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(
          AppStrings.notifications,
          style: TextStyle(color: colors.textPrimary),
        ),
      ),
      body: asyncNotifs.when(
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications yet',
              subtitle: 'Likes and follow requests will show up here.',
            );
          }

          return RefreshIndicator(
            color: colors.accentPrimary,
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSizes.lg),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
              itemBuilder: (context, index) {
                final n = items[index];
                final timeAgo = _timeAgo(n.createdAt);
                final isBusy =
                    n.followRequestId != null &&
                    _busyRequestIds.contains(n.followRequestId);

                return _NotificationTile(
                  notification: n,
                  timeAgo: timeAgo,
                  isBusy: isBusy,
                  onAccept: () => _acceptFollowRequest(n),
                  onDeny: () => _denyFollowRequest(n),
                );
              },
            ),
          );
        },
        loading: () =>
            const AppLoadingState(message: 'Loading notifications...'),
        error: (e, _) => AppErrorState(
          title: 'Unable to load notifications',
          message: e.toString(),
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final String timeAgo;
  final bool isBusy;
  final VoidCallback onAccept;
  final VoidCallback onDeny;

  const _NotificationTile({
    required this.notification,
    required this.timeAgo,
    required this.isBusy,
    required this.onAccept,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final text = switch (notification.type) {
      AppNotificationType.like =>
        'the "${notification.actorUsername}" liked your post',
      AppNotificationType.followRequest =>
        'the "${notification.actorUsername}" sent you a follow request',
    };

    return AppGlassCard(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Avatar(url: notification.actorProfilePic),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeAgo,
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
                if (notification.type == AppNotificationType.followRequest) ...[
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isBusy ? null : onAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.accentPrimary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusLg,
                              ),
                            ),
                          ),
                          child: isBusy
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                                )
                              : const Text(
                                  'Accept',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isBusy ? null : onDeny,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.textPrimary,
                            side: BorderSide(color: colors.borderStrong),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusLg,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Deny',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
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
    final colors = context.semanticColors;
    final hasUrl = url != null && url!.trim().isNotEmpty;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            colors.accentPrimary,
            colors.accentPrimary.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: colors.borderStrong, width: 1),
      ),
      child: ClipOval(
        child: hasUrl
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.person, color: Colors.white, size: 20),
              )
            : const Icon(Icons.person, color: Colors.white, size: 20),
      ),
    );
  }
}
