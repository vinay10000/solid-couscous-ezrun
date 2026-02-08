import 'dart:ui';

/// Liquid Glass Design System Colors
/// Inspired by Apple's translucent glass UI
abstract class AppColors {
  // ============================================
  // BASE BACKGROUNDS
  // ============================================

  /// Primary dark background
  static const background = Color(0xFF050510);

  /// Secondary background for depth
  static const backgroundSecondary = Color(0xFF0A0A1A);

  /// Tertiary background for nested elements
  static const backgroundTertiary = Color(0xFF11111B);

  /// Light theme primary background
  static const backgroundLight = Color(0xFFF3F6FA);

  /// Light theme raised surface
  static const backgroundSecondaryLight = Color(0xFFFFFFFF);

  /// Light theme tertiary surface
  static const backgroundTertiaryLight = Color(0xFFE9EEF5);

  // ============================================
  // LIQUID GLASS SURFACES
  // ============================================

  /// Light glass overlay (10% white)
  static const glassLight = Color(0x1AFFFFFF);

  /// Medium glass overlay (15% white)
  static const glassMedium = Color(0x26FFFFFF);

  /// Dark glass overlay (5% white)
  static const glassDark = Color(0x0DFFFFFF);

  /// Light glass border (20% white)
  static const glassBorderLight = Color(0x33FFFFFF);

  /// Subtle glass border (10% white)
  static const glassBorderSubtle = Color(0x1AFFFFFF);

  /// Specular highlight for top edge glow (30% white)
  static const specularHighlight = Color(0x4DFFFFFF);

  // ============================================
  // PRIMARY ACCENT
  // ============================================

  /// Primary cyan-blue accent
  static const primary = Color(0xFF00D4FF);

  /// Light theme primary accent variant
  static const primaryLightTheme = Color(0xFF0076A9);

  /// Lighter primary variant
  static const primaryLight = Color(0xFF48E5FF);

  /// Darker primary variant
  static const primaryDark = Color(0xFF00A8CC);

  /// Primary glow for buttons (30% opacity)
  static const primaryGlow = Color(0x4D00D4FF);

  // ============================================
  // SECONDARY ACCENT
  // ============================================

  /// Secondary pink accent
  static const secondary = Color(0xFFFF6B9D);

  /// Secondary glow
  static const secondaryGlow = Color(0x4DFF6B9D);

  // ============================================
  // TERRITORY COLORS
  // ============================================

  /// User's captured territory (vibrant green)
  static const territoryUser = Color(0xFF00FF88);

  /// User territory glow
  static const territoryUserGlow = Color(0x4D00FF88);

  /// Enemy territory (vibrant red)
  static const territoryEnemy = Color(0xFFFF4466);

  /// Enemy territory glow
  static const territoryEnemyGlow = Color(0x4DFF4466);

  /// Neutral/unclaimed territory
  static const territoryNeutral = Color(0xFF4A5568);

  /// Contested territory (yellow)
  static const territoryContested = Color(0xFFFFB800);

  // ============================================
  // TEXT COLORS
  // ============================================

  /// Primary text (white)
  static const textPrimary = Color(0xFFFFFFFF);

  /// Light theme primary text
  static const textPrimaryLight = Color(0xFF0E1525);

  /// Secondary text (70% white)
  static const textSecondary = Color(0xB3FFFFFF);

  /// Light theme secondary text
  static const textSecondaryLight = Color(0xCC1D2A3A);

  /// Muted text (40% white)
  static const textMuted = Color(0x66FFFFFF);

  /// Light theme muted text
  static const textMutedLight = Color(0x80303E52);

  /// Disabled text (20% white)
  static const textDisabled = Color(0x33FFFFFF);

  // ============================================
  // STATUS COLORS
  // ============================================

  /// Success (green)
  static const success = Color(0xFF00FF88);

  /// Success for light theme
  static const successLightTheme = Color(0xFF138B52);

  /// Warning (yellow)
  static const warning = Color(0xFFFFB800);

  /// Warning for light theme
  static const warningLightTheme = Color(0xFF9C6900);

  /// Error (red)
  static const error = Color(0xFFFF4466);

  /// Error for light theme
  static const errorLightTheme = Color(0xFFCC2A48);

  /// Info (cyan)
  static const info = Color(0xFF00D4FF);

  /// Light theme glass background
  static const glassLightTheme = Color(0xD9FFFFFF);

  /// Light theme subtle border
  static const borderSubtleLight = Color(0x1F1A365D);

  /// Light theme stronger border
  static const borderStrongLight = Color(0x33234366);
}
