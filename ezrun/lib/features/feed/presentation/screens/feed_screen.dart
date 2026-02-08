import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../data/providers/feed_providers.dart';
import 'create_post_screen.dart';
import '../widgets/feed_post_card.dart';

/// Feed Screen
/// - Explore: posts from any users
/// - Following: posts from users the current user follows
///
/// Data wiring to Supabase is added in later steps; this screen provides the UI shell.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.lg,
                AppSizes.lg,
                AppSizes.lg,
                AppSizes.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Feed',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Create post',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CreatePostScreen(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.add_box_outlined,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: colors.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: colors.borderSubtle, width: 1),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: colors.accentPrimary.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: colors.textPrimary,
                  unselectedLabelColor: colors.textSecondary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'Explore'),
                    Tab(text: 'Following'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _PostsTab(tab: FeedTab.explore),
                  _PostsTab(tab: FeedTab.following),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostsTab extends ConsumerWidget {
  final FeedTab tab;
  const _PostsTab({required this.tab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.semanticColors;
    final asyncPosts = ref.watch(feedPostsProvider(tab));
    return asyncPosts.when(
      data: (posts) {
        if (posts.isEmpty) {
          return AppEmptyState(
            icon: Icons.photo_library_outlined,
            title: tab == FeedTab.explore ? 'No posts yet' : 'Nothing here yet',
            subtitle: tab == FeedTab.explore
                ? 'Be the first runner to post a photo.'
                : 'Follow runners to see their posts here.',
          );
        }
        return RefreshIndicator(
          color: colors.accentPrimary,
          onRefresh: () async {
            ref.invalidate(feedPostsProvider(tab));
            await ref.read(feedPostsProvider(tab).future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(top: AppSizes.sm),
            itemCount: posts.length,
            itemBuilder: (context, index) =>
                FeedPostCard(post: posts[index], tab: tab),
          ),
        );
      },
      error: (e, _) => Center(
        child: AppErrorState(
          title: 'Unable to Load Posts',
          message: e.toString(),
          onRetry: () => ref.invalidate(feedPostsProvider(tab)),
        ),
      ),
      loading: () => AppLoadingState(
        message: tab == FeedTab.explore
            ? 'Loading explore feed...'
            : 'Loading following feed...',
      ),
    );
  }
}
