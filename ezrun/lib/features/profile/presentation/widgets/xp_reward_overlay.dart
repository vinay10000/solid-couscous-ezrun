import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../domain/entities/user_level.dart';

/// Shows a celebratory overlay when user earns XP.
class XpRewardOverlay {
  static void show(
    BuildContext context, {
    required int xpEarned,
    UserLevel? oldLevel,
    UserLevel? newLevel,
  }) {
    final overlay = OverlayEntry(
      builder: (context) => _XpRewardWidget(
        xpEarned: xpEarned,
        oldLevel: oldLevel,
        newLevel: newLevel,
      ),
    );

    Overlay.of(context).insert(overlay);

    // Auto-dismiss after animation
    Future.delayed(const Duration(milliseconds: 2500), () {
      overlay.remove();
    });
  }
}

class _XpRewardWidget extends StatefulWidget {
  final int xpEarned;
  final UserLevel? oldLevel;
  final UserLevel? newLevel;

  const _XpRewardWidget({required this.xpEarned, this.oldLevel, this.newLevel});

  @override
  State<_XpRewardWidget> createState() => _XpRewardWidgetState();
}

class _XpRewardWidgetState extends State<_XpRewardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool get _leveledUp =>
      widget.oldLevel != null &&
      widget.newLevel != null &&
      widget.newLevel!.currentLevel > widget.oldLevel!.currentLevel;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
          ),
        );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _leveledUp
                        ? [
                            AppColors.secondary.withOpacity(0.95),
                            AppColors.primary.withOpacity(0.95),
                          ]
                        : [
                            AppColors.primary.withOpacity(0.95),
                            AppColors.primary.withOpacity(0.85),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_leveledUp ? AppColors.secondary : AppColors.primary)
                              .withOpacity(0.5),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_leveledUp) ...[
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: AppSizes.sm),
                      const Text(
                        'LEVEL UP!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You reached Level ${widget.newLevel!.currentLevel}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md,
                          vertical: AppSizes.xs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusSm,
                          ),
                        ),
                        child: Text(
                          '+${widget.xpEarned} XP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        '+${widget.xpEarned} XP',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (widget.newLevel != null) ...[
                        Text(
                          '${widget.newLevel!.currentXp} / ${widget.newLevel!.xpForNextLevel} XP to Level ${widget.newLevel!.currentLevel + 1}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple snackbar variant for XP rewards.
class XpRewardSnackbar {
  static void show(
    BuildContext context, {
    required int xpEarned,
    bool leveledUp = false,
    int? newLevel,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              leveledUp ? Icons.emoji_events_rounded : Icons.star_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Text(
                leveledUp
                    ? 'Level Up! You\'re now Level $newLevel (+$xpEarned XP)'
                    : '+$xpEarned XP earned!',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: leveledUp ? AppColors.secondary : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
