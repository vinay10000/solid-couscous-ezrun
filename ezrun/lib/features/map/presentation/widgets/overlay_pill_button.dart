import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_semantic_colors.dart';

class OverlayPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData icon;

  const OverlayPillButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceRaised.withOpacity(0.92),
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            border: Border.all(color: colors.borderSubtle, width: 1),
            boxShadow: [
              BoxShadow(
                color: colors.shadowSoft,
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: colors.textPrimary),
              const SizedBox(width: AppSizes.sm),
              Text(
                label,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
