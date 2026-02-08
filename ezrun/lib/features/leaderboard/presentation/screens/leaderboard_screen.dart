import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../data/providers/leaderboard_providers.dart';
import '../widgets/leaderboard_list_item.dart';
import '../widgets/top_three_podium.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.semanticColors;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final leaderboardAsync = ref.watch(globalLeaderboardProvider);

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isLight
                ? [
                    colors.accentPrimary.withOpacity(0.10),
                    colors.surfaceRaised,
                    colors.surfaceBase,
                  ]
                : [
                    AppColors.primaryGlow,
                    AppColors.backgroundSecondary,
                    AppColors.background,
                  ],
          ),
        ),
        child: SafeArea(
          child: leaderboardAsync.when(
            data: (entries) {
              if (entries.isEmpty) {
                return _buildEmptyState();
              }

              // Extract top 3 for podium
              final topThree = entries.take(3).toList();
              // The rest for the list
              final rest = entries.skip(3).toList();

              // Find current user entry
              LeaderboardEntry? currentUserEntry;
              try {
                currentUserEntry = entries.firstWhere((e) => e.isCurrentUser);
              } catch (_) {
                currentUserEntry = null;
              }

              return Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(globalLeaderboardProvider);
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    backgroundColor: AppColors.backgroundSecondary,
                    color: colors.accentPrimary,
                    child: CustomScrollView(
                      slivers: [
                        // Podium
                        SliverToBoxAdapter(
                          child: TopThreePodium(
                            topThree: topThree,
                            onUserTap: (userId) {
                              final entry = topThree.firstWhere(
                                (e) => e.userId == userId,
                              );
                              _navigateToProfile(context, entry);
                            },
                          ),
                        ),

                        // Rest of the list
                        SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final entry = rest[index];
                            return LeaderboardListItem(
                              entry: entry,
                              isTopThree: false,
                              onTap: () => _navigateToProfile(context, entry),
                            );
                          }, childCount: rest.length),
                        ),

                        // Spacing for the bottom fixed bar
                        const SliverToBoxAdapter(child: SizedBox(height: 80)),
                      ],
                    ),
                  ),

                  // Fixed Bottom User Rank Bar
                  if (currentUserEntry != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.primary.withOpacity(0.5),
                              colors.surfaceBase,
                            ],
                            stops: const [0.0, 0.1],
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.surfaceRaised.withOpacity(0.95),
                            border: const Border(
                              top: BorderSide(
                                color: AppColors.glassBorderLight,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, -5),
                              ),
                            ],
                          ),
                          child: LeaderboardListItem(
                            entry: currentUserEntry,
                            isTopThree: currentUserEntry.rank <= 3,
                            onTap: () =>
                                _navigateToProfile(context, currentUserEntry!),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () =>
                const AppLoadingState(message: 'Loading rankings...'),
            error: (error, stack) => _buildErrorState(context, ref, error),
          ),
        ),
      ),
    );
  }

  void _navigateToProfile(BuildContext context, LeaderboardEntry entry) {
    if (!entry.isCurrentUser) {
      context.push('/u/${entry.userId}');
    }
  }

  Widget _buildEmptyState() => const AppEmptyState(
    icon: Icons.leaderboard,
    title: 'No rankings available yet',
    subtitle: 'Start running to climb the leaderboard!',
  );

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return AppErrorState(
      title: 'Failed to load rankings',
      message: error.toString(),
      onRetry: () => ref.invalidate(globalLeaderboardProvider),
    );
  }
}
