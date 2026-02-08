import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/run_entity.dart';
import '../../data/providers/runs_providers.dart';
import '../../../profile/data/providers/level_providers.dart';
import '../../../profile/presentation/widgets/xp_reward_overlay.dart';
import '../../../profile/domain/entities/user_level.dart';

class AddCustomRunSheet extends ConsumerStatefulWidget {
  final RunEntity? initialRun;

  const AddCustomRunSheet({super.key, this.initialRun});

  static Future<void> show(
    BuildContext context, {
    RunEntity? initialRun,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => AddCustomRunSheet(initialRun: initialRun),
    );
  }

  @override
  ConsumerState<AddCustomRunSheet> createState() => _AddCustomRunSheetState();
}

class _AddCustomRunSheetState extends ConsumerState<AddCustomRunSheet> {
  final _distanceCtrl = TextEditingController();
  final _minutesCtrl = TextEditingController();
  final _secondsCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  bool _saving = false;

  bool get _isEdit => widget.initialRun != null;

  @override
  void initState() {
    super.initState();
    final run = widget.initialRun;
    if (run == null) return;
    _distanceCtrl.text = run.distanceKm.toStringAsFixed(2);
    final minutes = (run.durationSeconds ~/ 60).clamp(0, 1 << 30);
    final seconds = (run.durationSeconds % 60).clamp(0, 59);
    _minutesCtrl.text = minutes.toString();
    _secondsCtrl.text = seconds.toString();
    _noteCtrl.text = run.note ?? '';
  }

  @override
  void dispose() {
    _distanceCtrl.dispose();
    _minutesCtrl.dispose();
    _secondsCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  int _parseInt(String v) => int.tryParse(v.trim()) ?? 0;
  double _parseDouble(String v) => double.tryParse(v.trim()) ?? 0.0;

  Future<void> _save() async {
    if (_saving) return;

    final distanceKm = _parseDouble(_distanceCtrl.text);
    final minutes = _parseInt(_minutesCtrl.text);
    final seconds = _parseInt(_secondsCtrl.text);
    final durationSeconds = (minutes * 60) + seconds;

    String? error;
    if (distanceKm <= 0) {
      error = 'Enter a valid distance (km).';
    } else if (durationSeconds <= 0) {
      error = 'Enter a valid duration.';
    } else if (seconds >= 60) {
      error = 'Seconds must be less than 60.';
    }

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _saving = true);

    // Capture old level for comparison (only for new runs)
    UserLevel? oldLevel;
    if (!_isEdit) {
      try {
        oldLevel = await ref.read(userLevelProvider.future);
      } catch (e) {
        // Level system might not be set up yet
      }
    }

    try {
      final repo = ref.read(runsRepositoryProvider);
      if (_isEdit) {
        await repo.updateCustomRun(
          runId: widget.initialRun!.id,
          distanceKm: distanceKm,
          durationSeconds: durationSeconds,
          note: _noteCtrl.text,
        );
      } else {
        await repo.addCustomRun(
          distanceKm: distanceKm,
          durationSeconds: durationSeconds,
          note: _noteCtrl.text,
        );
      }
      ref.invalidate(myRunsProvider);

      if (mounted) {
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Custom run updated' : 'Custom run added'),
            backgroundColor: AppColors.success,
          ),
        );

        // Show XP reward for new runs
        if (!_isEdit && oldLevel != null) {
          try {
            // Invalidate and refetch level
            ref.invalidate(userLevelProvider);
            final newLevel = await ref.read(userLevelProvider.future);

            // Show reward overlay
            if (mounted) {
              XpRewardOverlay.show(
                context,
                xpEarned: LevelSystem.xpPerRun,
                oldLevel: oldLevel,
                newLevel: newLevel,
              );
            }
          } catch (e) {
            // Silently fail if level system is not set up
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.96),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.lg,
            AppSizes.md,
            AppSizes.lg,
            AppSizes.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              const Text(
                'Add custom run',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (_isEdit) ...[
                const SizedBox(height: 4),
                Text(
                  'Editing your custom run',
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: AppSizes.sm),
              Text(
                'Log a run manually (distance, duration, note).',
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              _Label('Distance (km)'),
              const SizedBox(height: AppSizes.xs),
              TextField(
                controller: _distanceCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: _decoration('e.g. 2.00'),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSizes.lg),
              _Label('Duration'),
              const SizedBox(height: AppSizes.xs),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minutesCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _decoration('Minutes'),
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: TextField(
                      controller: _secondsCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _decoration('Seconds'),
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              _Label('Note (optional)'),
              const SizedBox(height: AppSizes.xs),
              TextField(
                controller: _noteCtrl,
                maxLines: 3,
                decoration: _decoration('e.g. Easy treadmill / felt great'),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSizes.xl),
              SizedBox(
                width: double.infinity,
                height: AppSizes.buttonMd,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEdit ? 'Update' : 'Save',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.6)),
      filled: true,
      fillColor: AppColors.backgroundSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: 14,
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
