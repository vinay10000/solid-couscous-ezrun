import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color surfaceBase;
  final Color surfaceRaised;
  final Color surfaceGlass;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accentPrimary;
  final Color success;
  final Color warning;
  final Color error;
  final Color borderSubtle;
  final Color borderStrong;
  final Color shadowSoft;
  final Color shadowStrong;

  const AppSemanticColors({
    required this.surfaceBase,
    required this.surfaceRaised,
    required this.surfaceGlass,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accentPrimary,
    required this.success,
    required this.warning,
    required this.error,
    required this.borderSubtle,
    required this.borderStrong,
    required this.shadowSoft,
    required this.shadowStrong,
  });

  static const AppSemanticColors dark = AppSemanticColors(
    surfaceBase: AppColors.background,
    surfaceRaised: AppColors.backgroundSecondary,
    surfaceGlass: AppColors.glassMedium,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    accentPrimary: AppColors.primary,
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    borderSubtle: AppColors.glassBorderSubtle,
    borderStrong: AppColors.glassBorderLight,
    shadowSoft: Color(0x29000000),
    shadowStrong: Color(0x4D000000),
  );

  static const AppSemanticColors light = AppSemanticColors(
    surfaceBase: AppColors.backgroundLight,
    surfaceRaised: AppColors.backgroundSecondaryLight,
    surfaceGlass: AppColors.glassLightTheme,
    textPrimary: AppColors.textPrimaryLight,
    textSecondary: AppColors.textSecondaryLight,
    textMuted: AppColors.textMutedLight,
    accentPrimary: AppColors.primaryLightTheme,
    success: AppColors.successLightTheme,
    warning: AppColors.warningLightTheme,
    error: AppColors.errorLightTheme,
    borderSubtle: AppColors.borderSubtleLight,
    borderStrong: AppColors.borderStrongLight,
    shadowSoft: Color(0x14000000),
    shadowStrong: Color(0x29000000),
  );

  @override
  AppSemanticColors copyWith({
    Color? surfaceBase,
    Color? surfaceRaised,
    Color? surfaceGlass,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accentPrimary,
    Color? success,
    Color? warning,
    Color? error,
    Color? borderSubtle,
    Color? borderStrong,
    Color? shadowSoft,
    Color? shadowStrong,
  }) {
    return AppSemanticColors(
      surfaceBase: surfaceBase ?? this.surfaceBase,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceGlass: surfaceGlass ?? this.surfaceGlass,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      shadowSoft: shadowSoft ?? this.shadowSoft,
      shadowStrong: shadowStrong ?? this.shadowStrong,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      surfaceBase: Color.lerp(surfaceBase, other.surfaceBase, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceGlass: Color.lerp(surfaceGlass, other.surfaceGlass, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      shadowSoft: Color.lerp(shadowSoft, other.shadowSoft, t)!,
      shadowStrong: Color.lerp(shadowStrong, other.shadowStrong, t)!,
    );
  }
}

extension SemanticColorsContextExt on BuildContext {
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.dark;
}
