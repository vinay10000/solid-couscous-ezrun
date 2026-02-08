import 'dart:ui';

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Background layer for the Profile screen "blue/green" theme.
///
/// This is intentionally subtle so it works well with the app's dark UI.
/// When disabled, it falls back to the normal `AppColors.background`.
class ProfileThemeBackground extends StatelessWidget {
  final bool enabled;

  const ProfileThemeBackground({super.key, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: AppColors.background)),
          if (enabled) ...[
            // Soft "aqua" wash at the top, like the reference UI.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryLight.withOpacity(0.28),
                      AppColors.territoryUser.withOpacity(0.18),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.35, 0.80],
                  ),
                ),
              ),
            ),
            // A couple of blurred blobs to make it feel organic.
            Positioned(
              top: -120,
              left: -80,
              child: _BlurBlob(
                color: AppColors.primaryLight.withOpacity(0.55),
                size: 280,
              ),
            ),
            Positioned(
              top: -140,
              right: -110,
              child: _BlurBlob(
                color: AppColors.territoryUser.withOpacity(0.45),
                size: 320,
              ),
            ),
            // Light blur pass to smooth any banding.
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: const SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BlurBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _BlurBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}
