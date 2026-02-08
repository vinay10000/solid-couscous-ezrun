import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../data/providers/territory_providers.dart';
import '../../domain/entities/territory_entity.dart';

class TerritoryDetailsBottomSheet {
  static Future<void> show(
    BuildContext context, {
    required TerritoryEntity territory,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TerritoryDetailsSheet(territory: territory),
    );
  }
}

class _TerritoryDetailsSheet extends ConsumerWidget {
  final TerritoryEntity territory;

  const _TerritoryDetailsSheet({required this.territory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveRow = ref.watch(territoryRowStreamProvider(territory.id));

    final displayName = (territory.username?.trim().isNotEmpty ?? false)
        ? territory.username!.trim()
        : 'Unknown runner';

    final profileColor =
        _tryParseHexColor(territory.profileColor) ?? AppColors.primary;

    final createdAt = liveRow.maybeWhen(
      data: (row) {
        final raw = row?['created_at'];
        if (raw is String) return DateTime.tryParse(raw);
        return null;
      },
      orElse: () => null,
    );

    final areaSqMeters =
        liveRow.maybeWhen(
          data: (row) => (row?['area_sq_meters'] as num?)?.toDouble(),
          orElse: () => null,
        ) ??
        territory.areaSqMeters;

    final dt = createdAt ?? territory.createdAt;
    final subtitle = _formatFullDateTime(dt);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSizes.lg,
          right: AppSizes.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.lg,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.background.withOpacity(0.98),
                AppColors.backgroundSecondary.withOpacity(0.92),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 18,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Intentionally no "drag handle" bar to match the reference popup UI.
                const SizedBox(height: AppSizes.xs),

                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        onTap: () {
                          context.pushNamed(
                            'publicProfile',
                            pathParameters: {'userId': territory.userId},
                          );
                        },
                        child: Row(
                          children: [
                            _Avatar(
                              profilePic: territory.profilePic,
                              fallbackColor: profileColor,
                            ),
                            const SizedBox(width: AppSizes.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.textSecondary
                                          .withOpacity(0.9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '—',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.textSecondary
                                          .withOpacity(0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final choice = await showModalBottomSheet<String>(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (_) =>
                              _ActionSheet(profileColor: profileColor),
                        );
                        if (!context.mounted) return;
                        if (choice == 'profile') {
                          context.pushNamed(
                            'publicProfile',
                            pathParameters: {'userId': territory.userId},
                          );
                        } else if (choice == 'close') {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(
                        Icons.more_horiz,
                        color: AppColors.textSecondary,
                      ),
                      tooltip: 'More',
                    ),
                  ],
                ),

                const SizedBox(height: AppSizes.lg),

                Text(
                  territory.displayRunTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),

                const SizedBox(height: AppSizes.md),

                // Intentionally no divider line (white horizontal bar).
                const SizedBox(height: AppSizes.md),

                Row(
                  children: [
                    _Metric(
                      value: _formatDistanceCompact(territory.runDistanceKm),
                      label: 'Distance',
                      valueColor: AppColors.textPrimary,
                    ),
                    _Metric(
                      value: _formatDurationCompact(
                        territory.runDurationSeconds,
                      ),
                      label: 'Duration',
                      valueColor: AppColors.textPrimary,
                    ),
                    _Metric(
                      value: _formatPaceCompact(territory.runAvgPaceSecPerKm),
                      label: 'Avg Pace',
                      valueColor: AppColors.textPrimary,
                    ),
                    _Metric(
                      value: _formatAreaCompact(areaSqMeters),
                      label: 'Terra area',
                      valueColor: profileColor,
                    ),
                  ],
                ),

                // Keep this super subtle; only shown when stream errors (useful for debugging).
                liveRow.when(
                  data: (_) => const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.only(top: AppSizes.sm),
                    child: Text(
                      'Sync unavailable',
                      style: TextStyle(
                        color: AppColors.warning.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color? _tryParseHexColor(String hex) {
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length != 6) return null;
    final v = int.tryParse('FF$cleaned', radix: 16);
    if (v == null) return null;
    return Color(v);
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final mm = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$mm $ampm';
  }

  static String _formatFullDateTime(DateTime dt) {
    // Wednesday 24 December 06:05 AM
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
    return '$w ${dt.day} $m ${_formatTime(dt)}';
  }

  static String _formatDistanceCompact(double? km) {
    if (km == null) return '—';
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)}M';
    return '${km.toStringAsFixed(2)}KM';
  }

  static String _formatDurationCompact(int? seconds) {
    if (seconds == null) return '—';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString()}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString()}:${s.toString().padLeft(2, '0')}';
  }

  static String _formatPaceCompact(int? secPerKm) {
    if (secPerKm == null || secPerKm == 0) return '—';
    final m = secPerKm ~/ 60;
    final s = secPerKm % 60;
    return '${m.toString()}:${s.toString().padLeft(2, '0')}/KM';
  }

  static String _formatAreaCompact(double areaSqMeters) {
    final km2 = areaSqMeters / 1000000.0;
    if (km2 < 0.01) return '${areaSqMeters.toStringAsFixed(0)}M²';
    if (km2 < 10) return '${km2.toStringAsFixed(2)}KM²';
    return '${km2.toStringAsFixed(1)}KM²';
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _Metric({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.85),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? profilePic;
  final Color fallbackColor;

  const _Avatar({required this.profilePic, required this.fallbackColor});

  @override
  Widget build(BuildContext context) {
    final url = profilePic?.trim();
    final hasUrl = url != null && url.isNotEmpty;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            fallbackColor.withOpacity(0.95),
            fallbackColor.withOpacity(0.35),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: ClipOval(
        child: hasUrl
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.person, color: Colors.white),
              )
            : const Icon(Icons.person, color: Colors.white),
      ),
    );
  }
}

class _ActionSheet extends StatelessWidget {
  final Color profileColor;
  const _ActionSheet({required this.profileColor});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary.withOpacity(0.98),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.person, color: profileColor),
                title: const Text(
                  'View profile',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onTap: () => Navigator.of(context).pop('profile'),
              ),
              ListTile(
                leading: const Icon(
                  Icons.close,
                  color: AppColors.textSecondary,
                ),
                title: const Text(
                  'Close',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onTap: () => Navigator.of(context).pop('close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
