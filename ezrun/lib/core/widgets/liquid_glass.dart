import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// Liquid Glass container widget
/// Creates a translucent glass effect with backdrop blur and specular highlight
class LiquidGlass extends StatelessWidget {
  /// Child widget to display inside the glass container
  final Widget child;

  /// Blur sigma for backdrop filter
  final double blur;

  /// Background color of the glass (default: glassMedium)
  final Color? backgroundColor;

  /// Border radius of the container
  final double borderRadius;

  /// Whether to show specular highlight at top edge
  final bool showSpecular;

  /// Padding inside the container
  final EdgeInsetsGeometry? padding;

  /// Fixed width (optional)
  final double? width;

  /// Fixed height (optional)
  final double? height;

  /// Border color (default: glassBorderLight)
  final Color? borderColor;

  /// Callback when tapped
  final VoidCallback? onTap;

  const LiquidGlass({
    super.key,
    required this.child,
    this.blur = AppSizes.blurMedium,
    this.backgroundColor,
    this.borderRadius = AppSizes.radiusLg,
    this.showSpecular = true,
    this.padding,
    this.width,
    this.height,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.glassMedium,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? AppColors.glassBorderLight,
                width: 1,
              ),
              boxShadow: [
                // Outer shadow for depth
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Specular highlight at top
                if (showSpecular)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 1,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.specularHighlight,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                // Content
                Padding(
                  padding: padding ?? const EdgeInsets.all(AppSizes.md),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A lighter variant of Liquid Glass with less opacity
class LiquidGlassLight extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const LiquidGlassLight({
    super.key,
    required this.child,
    this.borderRadius = AppSizes.radiusMd,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      blur: AppSizes.blurLight,
      backgroundColor: AppColors.glassLight,
      borderColor: AppColors.glassBorderSubtle,
      borderRadius: borderRadius,
      showSpecular: false,
      padding: padding,
      onTap: onTap,
      child: child,
    );
  }
}

/// A card variant using Liquid Glass
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          margin ??
          const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm,
          ),
      child: LiquidGlass(
        padding: padding ?? const EdgeInsets.all(AppSizes.md),
        onTap: onTap,
        child: child,
      ),
    );
  }
}
