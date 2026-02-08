import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/state/ui_visibility_providers.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../runs/data/providers/runs_providers.dart';

/// Main shell screen with Liquid Glass bottom navigation
class MainShellScreen extends ConsumerWidget {
  final Widget child;

  const MainShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showNav = ref.watch(bottomNavVisibleProvider);
    return Scaffold(
      body: Stack(children: [child, const _RunsPreloader()]),
      extendBody: true,
      bottomNavigationBar: showNav ? const _LiquidGlassBottomNav() : null,
      floatingActionButton: showNav ? _buildStartRunFab(context) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildStartRunFab(BuildContext context) {
    final colors = context.semanticColors;
    return GestureDetector(
      onTap: () => context.push('/run'),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.accentPrimary,
              colors.accentPrimary.withOpacity(0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colors.accentPrimary.withOpacity(0.35),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
}

/// Invisible widget that triggers loading of the user's runs when the app shell
/// is first built (so My Runs opens instantly later).
class _RunsPreloader extends ConsumerWidget {
  const _RunsPreloader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Start the fetch; ignore the value here.
    ref.watch(myRunsProvider);
    return const SizedBox.shrink();
  }
}

class _LiquidGlassBottomNav extends StatefulWidget {
  const _LiquidGlassBottomNav();

  @override
  State<_LiquidGlassBottomNav> createState() => _LiquidGlassBottomNavState();
}

class _LiquidGlassBottomNavState extends State<_LiquidGlassBottomNav> {
  static const bool _enableRealLiquidGlass = bool.fromEnvironment(
    'ENABLE_LIQUID_GLASS',
    defaultValue: false,
  );

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    switch (location) {
      case '/':
        return 0;
      case '/leaderboard':
        return 1;
      case '/training':
        return 2;
      case '/feed':
        return 3;
      case '/profile':
        return 4;
      default:
        return 0;
    }
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/leaderboard');
        break;
      case 2:
        context.go('/training');
        break;
      case 3:
        context.go('/feed');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final selectedIndex = _getSelectedIndex(context);

    final navContent = SizedBox(
      height: AppSizes.bottomNavHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(
            icon: Iconsax.map,
            activeIcon: Iconsax.map5,
            label: 'Map',
            isSelected: selectedIndex == 0,
            accentColor: colors.accentPrimary,
            mutedColor: colors.textMuted,
            onTap: () => _onNavTap(0),
          ),
          _NavItem(
            icon: Iconsax.ranking,
            activeIcon: Iconsax.ranking5,
            label: 'Ranking',
            isSelected: selectedIndex == 1,
            accentColor: colors.accentPrimary,
            mutedColor: colors.textMuted,
            onTap: () => _onNavTap(1),
          ),
          // Center space for FAB
          const SizedBox(width: 64),
          _NavItem(
            icon: Iconsax.activity,
            activeIcon: Iconsax.activity5,
            label: 'Feed',
            isSelected: selectedIndex == 3,
            accentColor: colors.accentPrimary,
            mutedColor: colors.textMuted,
            onTap: () => _onNavTap(3),
          ),
          _NavItem(
            icon: Iconsax.profile_circle,
            activeIcon: Iconsax.profile_circle5,
            label: 'Profile',
            isSelected: selectedIndex == 4,
            accentColor: colors.accentPrimary,
            mutedColor: colors.textMuted,
            onTap: () => _onNavTap(4),
          ),
        ],
      ),
    );

    // Default: FakeGlass for Android safety/perf.
    // Enable real liquid glass only if you run with:
    // flutter run --dart-define ENABLE_LIQUID_GLASS=true
    final useFakeGlass = !_enableRealLiquidGlass;

    final glassSettings = LiquidGlassSettings(
      // Keep blur low-ish for perf; increase carefully on real devices.
      blur: useFakeGlass ? 10 : 12,
      thickness: useFakeGlass ? 0 : 14,
      glassColor: colors.surfaceGlass,
      lightIntensity: 1.2,
      saturation: 1.15,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        child: useFakeGlass
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceGlass,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                    border: Border.all(color: colors.borderStrong, width: 1),
                  ),
                  child: navContent,
                ),
              )
            : LiquidGlassLayer(
                settings: glassSettings,
                child: LiquidGlass(
                  shape: LiquidRoundedSuperellipse(
                    borderRadius: AppSizes.radiusXl,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      // Keep it mostly transparent; the shader provides the effect.
                      color: Colors.white.withOpacity(0.02),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.14),
                        width: 1,
                      ),
                    ),
                    child: navContent,
                  ),
                ),
              ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final Color accentColor;
  final Color mutedColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.mutedColor,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? accentColor : mutedColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? accentColor : mutedColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
