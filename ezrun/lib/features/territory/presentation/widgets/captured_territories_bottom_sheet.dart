import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../data/providers/territory_providers.dart';
import '../../domain/entities/territory_entity.dart';

class CapturedTerritoriesBottomSheet extends ConsumerStatefulWidget {
  const CapturedTerritoriesBottomSheet({super.key});

  static Future<TerritoryEntity?> show(BuildContext context) async {
    return await showModalBottomSheet<TerritoryEntity?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => const CapturedTerritoriesBottomSheet(),
    );
  }

  @override
  ConsumerState<CapturedTerritoriesBottomSheet> createState() =>
      _CapturedTerritoriesBottomSheetState();
}

enum _SortOption { date, area }

class _CapturedTerritoriesBottomSheetState
    extends ConsumerState<CapturedTerritoriesBottomSheet> {
  _SortOption _selectedSort = _SortOption.date;

  @override
  Widget build(BuildContext context) {
    final asyncTerritories = ref.watch(myTerritoriesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.25,
      maxChildSize: 1.0,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF101010), // Deep black/grey background
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusXl),
            ),
            border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSizes.sm),
              const _SheetGrabber(),
              const SizedBox(height: AppSizes.md),

              // Sorting Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                  ),
                  child: Row(
                    children: [
                      _SortTab(
                        label: 'Sort by Date',
                        isActive: _selectedSort == _SortOption.date,
                        onTap: () =>
                            setState(() => _selectedSort = _SortOption.date),
                      ),
                      _SortTab(
                        label: 'Sort by Area',
                        isActive: _selectedSort == _SortOption.area,
                        onTap: () =>
                            setState(() => _selectedSort = _SortOption.area),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // List
              Expanded(
                child: asyncTerritories.when(
                  data: (territories) {
                    if (territories.isEmpty) {
                      return const _EmptyTerritories();
                    }

                    // Sort logic
                    final sorted = [...territories];
                    if (_selectedSort == _SortOption.date) {
                      sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    } else {
                      sorted.sort(
                        (a, b) => b.areaSqMeters.compareTo(a.areaSqMeters),
                      );
                    }

                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        ref.invalidate(myTerritoriesProvider);
                        await ref.read(myTerritoriesProvider.future);
                      },
                      child: ListView.separated(
                        controller: scrollController,
                        padding: EdgeInsets.only(
                          bottom:
                              MediaQuery.of(context).padding.bottom +
                              AppSizes.lg,
                        ),
                        itemCount: sorted.length,
                        separatorBuilder: (_, __) => Divider(
                          color: Colors.white.withOpacity(0.06),
                          height: 1,
                        ),
                        itemBuilder: (context, index) {
                          final territory = sorted[index];
                          return _TerritoryCard(
                            territory: territory,
                            onTap: () => Navigator.of(context).pop(territory),
                          );
                        },
                      ),
                    );
                  },
                  error: (e, _) => Center(
                    child: Text(
                      'Error loading territories',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SortTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SortTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetGrabber extends StatelessWidget {
  const _SheetGrabber();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
  }
}

class _EmptyTerritories extends StatelessWidget {
  const _EmptyTerritories();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 48),
          Icon(
            Icons.map_outlined,
            size: 48,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'No territories yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete closed loop runs to capture territories.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _TerritoryCard extends StatelessWidget {
  final TerritoryEntity territory;
  final VoidCallback onTap;

  const _TerritoryCard({required this.territory, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Area text logic
    final areaSqMeters = territory.areaSqMeters;
    final km2 = areaSqMeters / 1000000.0;
    String areaText;
    if (km2 < 0.01) {
      areaText = '${areaSqMeters.toStringAsFixed(0)}M²';
    } else {
      areaText = '${km2.toStringAsFixed(2)}KM²';
    }

    // Profile Pic logic
    final picUrl = territory.profilePic;
    final noPic = picUrl == null || picUrl.isEmpty;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    image: !noPic
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(picUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: noPic
                      ? const Icon(Icons.person, color: Colors.white70)
                      : null,
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatFullDateTime(territory.createdAt),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        territory
                            .displayRunTitle, // Using run note/title as location placeholder
                        style: const TextStyle(
                          color: Color(0xFF999999), // Muted grey
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatItem(
                  value: territory.formattedRunDistance
                      .replaceAll(' ', '')
                      .toUpperCase(),
                  label: 'Distance',
                ),
                _StatItem(
                  value: territory.formattedRunDuration,
                  label: 'Duration',
                ),
                _StatItem(
                  value: territory.formattedRunPace.toUpperCase(),
                  label: 'Avg Pace',
                ),
                _StatItem(
                  value: areaText,
                  label: 'Terra area',
                  valueColor: const Color(0xFF4AF8D8), // Teal/Cyan color
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatFullDateTime(DateTime dt) {
    // e.g. Sunday 7 December 19:19 PM
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final w = weekdays[(dt.weekday - 1).clamp(0, 6)];
    final m = months[(dt.month - 1).clamp(0, 11)];

    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';

    return '$w ${dt.day} $m $h:$min $ampm';
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const _StatItem({required this.value, required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            fontFamily:
                'Inter', // Assuming standard font, but style implies heavy weight
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
