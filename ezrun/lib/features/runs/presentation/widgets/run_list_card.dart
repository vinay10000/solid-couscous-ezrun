import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/run_entity.dart';
import '../utils/run_formatters.dart';

class RunListCard extends StatelessWidget {
  final RunEntity run;
  final String? currentUserProfilePic;
  final VoidCallback onViewRecap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RunListCard({
    super.key,
    required this.run,
    required this.currentUserProfilePic,
    required this.onViewRecap,
    this.onEdit,
    this.onDelete,
  });

  bool get _isPositiveStatus {
    final s = (run.status ?? '').toLowerCase();
    // Keep conservative: only show green for explicit success-ish markers.
    return s.contains('terra') ||
        s.contains('captured') ||
        s.contains('success') ||
        s == 'ok' ||
        s == 'completed';
  }

  bool get _isNegativeStatus {
    final s = (run.status ?? '').toLowerCase();
    final msg = (run.statusMessage ?? '').toLowerCase();
    return s.contains('reject') ||
        s.contains('fail') ||
        s.contains('error') ||
        msg.contains("can't") ||
        msg.contains('cant') ||
        msg.contains('not') ||
        msg.contains('treadmill');
  }

  @override
  Widget build(BuildContext context) {
    final statusText = run.isCustom
        ? 'Custom run'
        : (run.statusMessage?.trim().isNotEmpty ?? false)
        ? run.statusMessage!.trim()
        : (run.status?.trim().isNotEmpty ?? false)
        ? run.status!.trim()
        : 'Run status pending';

    final chipBg = _isNegativeStatus
        ? AppColors.error.withOpacity(0.12)
        : _isPositiveStatus
        ? AppColors.success.withOpacity(0.12)
        : AppColors.textSecondary.withOpacity(0.10);

    final chipBorder = _isNegativeStatus
        ? AppColors.error.withOpacity(0.45)
        : _isPositiveStatus
        ? AppColors.success.withOpacity(0.45)
        : AppColors.textSecondary.withOpacity(0.25);

    final chipText = _isNegativeStatus
        ? AppColors.error
        : _isPositiveStatus
        ? AppColors.success
        : AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(profilePic: currentUserProfilePic),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  formatTimeAgo(run.createdAt),
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (run.isCustom && (onEdit != null || onDelete != null))
                _MoreButton(onEdit: onEdit, onDelete: onDelete),
              const SizedBox(width: AppSizes.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: run.isCustom
                      ? AppColors.primary.withOpacity(0.10)
                      : chipBg,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(color: chipBorder, width: 1),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: run.isCustom ? AppColors.primary : chipText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(value: formatKm(run.distanceKm), label: 'Distance'),
              _Stat(
                value: formatDurationHms(run.durationSeconds),
                label: 'Duration',
              ),
              _Stat(
                value: formatPacePerKm(run.avgPaceSecPerKm),
                label: 'Avg Pace',
              ),
            ],
          ),
          if (run.note != null && run.note!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSizes.sm),
            Text(
              run.note!.trim(),
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  formatRunDateLine(run.createdAt),
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onViewRecap,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: 8,
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text(
                  'View Recap',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _MoreButton({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await showModalBottomSheet<void>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => _ActionsSheet(onEdit: onEdit, onDelete: onDelete),
        );
      },
      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        ),
        child: Icon(
          Icons.more_horiz,
          size: 18,
          color: AppColors.textSecondary.withOpacity(0.95),
        ),
      ),
    );
  }
}

class _ActionsSheet extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ActionsSheet({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSizes.md),
        padding: const EdgeInsets.all(AppSizes.sm),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              ListTile(
                leading: const Icon(
                  Icons.edit,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                title: const Text(
                  'Edit',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onEdit?.call();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 20,
                ),
                title: const Text(
                  'Delete',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  onDelete?.call();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? profilePic;
  const _Avatar({required this.profilePic});

  @override
  Widget build(BuildContext context) {
    final url = profilePic;
    return Container(
      width: AppSizes.avatarSm,
      height: AppSizes.avatarSm,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.10), width: 1),
      ),
      child: ClipOval(
        child: url == null || url.trim().isEmpty
            ? Container(
                color: Colors.white.withOpacity(0.06),
                child: const Icon(
                  Icons.person,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              )
            : Image(image: CachedNetworkImageProvider(url), fit: BoxFit.cover),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
