import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../data/models/widget_config.dart';
import 'color_theme_selector.dart';

class WidgetPreviewCard extends StatelessWidget {
  final WidgetConfig config;

  const WidgetPreviewCard({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = widgetThemeOptions.firstWhere(
      (option) => option.theme == config.themeColor,
      orElse: () => widgetThemeOptions.first,
    );
    final textSize = _textSizeFor(config.textSize);
    final dayCount = _calculateDays(config.goalDate);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.12),
                        Colors.white.withOpacity(0.04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: AppSizes.md,
              right: AppSizes.md,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.run_circle_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.title.isEmpty ? 'DAYS' : config.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    dayCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: textSize,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    config.subtitle.isEmpty
                        ? 'Your next goal'
                        : config.subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: -40,
              bottom: -60,
              child: Transform.rotate(
                angle: -math.pi / 8,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateDays(DateTime goalDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(goalDate.year, goalDate.month, goalDate.day);
    final diff = target.difference(today).inDays;
    return diff.abs();
  }

  double _textSizeFor(WidgetTextSize size) {
    switch (size) {
      case WidgetTextSize.small:
        return 40;
      case WidgetTextSize.medium:
        return 52;
      case WidgetTextSize.large:
        return 64;
    }
  }
}
