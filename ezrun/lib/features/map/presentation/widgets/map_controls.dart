import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_semantic_colors.dart';

class MapControls extends StatelessWidget {
  final VoidCallback onRecenter;
  final Future<void> Function() onZoomIn;
  final Future<void> Function() onZoomOut;

  const MapControls({
    super.key,
    required this.onRecenter,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Positioned(
      bottom: AppSizes.xxl + 76, // Above the FAB
      right: AppSizes.lg,
      child: Column(
        children: [
          // Recenter
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceRaised.withOpacity(0.92),
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              boxShadow: [
                BoxShadow(
                  color: colors.shadowSoft,
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: IconButton(
              onPressed: onRecenter,
              icon: Icon(Icons.my_location, color: colors.accentPrimary),
              tooltip: 'Center on my location',
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          // Zoom
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceRaised.withOpacity(0.92),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: colors.shadowSoft,
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              children: [
                IconButton(
                  onPressed: () => onZoomIn(),
                  icon: Icon(Icons.add, color: colors.textPrimary, size: 20),
                  tooltip: 'Zoom in',
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
                Divider(height: 1, color: colors.borderSubtle),
                IconButton(
                  onPressed: () => onZoomOut(),
                  icon: Icon(Icons.remove, color: colors.textPrimary, size: 20),
                  tooltip: 'Zoom out',
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
