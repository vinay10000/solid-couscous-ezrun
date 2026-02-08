import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/state/ui_visibility_providers.dart';
import '../../data/providers/runs_providers.dart';
import 'run_list_card.dart';
import 'add_custom_run_sheet.dart';

class MyRunsBottomSheet extends ConsumerWidget {
  const MyRunsBottomSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      isDismissible: true,
      builder: (_) => const MyRunsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = Supabase.instance.client.auth.currentUser;
    final myProfilePic =
        (me?.userMetadata?['profile_picture_url'] as String?) ??
        (me?.userMetadata?['profile_pic'] as String?);

    final asyncRuns = ref.watch(myRunsProvider);

    return Stack(
      children: [
        // Background area that can be tapped to dismiss
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(color: Colors.transparent),
        ),
        // The actual bottom sheet
        DraggableScrollableSheet(
          initialChildSize: 0.25,
          minChildSize: 0.25,
          maxChildSize: 1.0,
          snap: true,
          snapSizes: const [0.25, 0.5, 0.75, 1.0],
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.96),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.radiusXl),
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                  width: 1,
                ),
              ),
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(myRunsProvider);
                  await ref.read(myRunsProvider.future);
                },
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    top: AppSizes.sm,
                    bottom: MediaQuery.of(context).padding.bottom + AppSizes.lg,
                  ),
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSizes.lg),
                      child: _Header(),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    asyncRuns.when(
                      data: (runs) {
                        if (runs.isEmpty) {
                          return const _EmptyRuns();
                        }
                        return Column(
                          children: [
                            for (final run in runs) ...[
                              RunListCard(
                                run: run,
                                currentUserProfilePic: myProfilePic,
                                onViewRecap: () {
                                  Navigator.of(context).pop();
                                  context.push('/run-summary/${run.id}');
                                },
                                onEdit: run.isCustom
                                    ? () async {
                                        ref
                                                .read(
                                                  bottomNavVisibleProvider
                                                      .notifier,
                                                )
                                                .state =
                                            false;
                                        try {
                                          await AddCustomRunSheet.show(
                                            context,
                                            initialRun: run,
                                          );
                                          ref.invalidate(myRunsProvider);
                                        } finally {
                                          ref
                                                  .read(
                                                    bottomNavVisibleProvider
                                                        .notifier,
                                                  )
                                                  .state =
                                              true;
                                        }
                                      }
                                    : null,
                                onDelete: run.isCustom
                                    ? () async {
                                        final confirmed =
                                            await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                backgroundColor: AppColors
                                                    .backgroundSecondary,
                                                title: const Text(
                                                  'Delete custom run?',
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                                content: const Text(
                                                  'This cannot be undone.',
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          ctx,
                                                        ).pop(false),
                                                    child: const Text(
                                                      'Cancel',
                                                      style: TextStyle(
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(
                                                          ctx,
                                                        ).pop(true),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          AppColors.error,
                                                    ),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );

                                        if (confirmed != true) return;
                                        try {
                                          final repo = ref.read(
                                            runsRepositoryProvider,
                                          );
                                          await repo.deleteRun(run.id);
                                          ref.invalidate(myRunsProvider);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text('Run deleted'),
                                                backgroundColor:
                                                    AppColors.success,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  e.toString().replaceFirst(
                                                    'Exception: ',
                                                    '',
                                                  ),
                                                ),
                                                backgroundColor:
                                                    AppColors.error,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    : null,
                              ),
                              const SizedBox(height: AppSizes.md),
                            ],
                          ],
                        );
                      },
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.lg,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(AppSizes.md),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusLg,
                            ),
                            border: Border.all(
                              color: AppColors.error.withOpacity(0.35),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            e.toString().replaceFirst('Exception: ', ''),
                            style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.only(top: AppSizes.xl),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Runs',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'View the statuses of your runs',
          style: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.9),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _EmptyRuns extends StatelessWidget {
  const _EmptyRuns();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.emptyRuns,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              AppStrings.emptyRunsMessage,
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'Pull down to refresh once you have runs.',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
