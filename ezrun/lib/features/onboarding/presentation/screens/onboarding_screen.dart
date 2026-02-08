import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_semantic_colors.dart';

/// Onboarding Screen - Modern carousel with gradient cards
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.9);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (!mounted) return;
    context.go('/sign-in');
  }

  final List<OnboardingFeature> _features = [
    OnboardingFeature(
      icon: Icons.map_outlined,
      title: 'Territory Capture',
      description:
          'Turn every run into conquered territory. Track your routes and claim the map as your own',
      centerColor: const Color(0xFF6DD579),
      edgeColor: const Color(0xFF145E2B),
    ),
    OnboardingFeature(
      icon: Icons.people_outline,
      title: 'Community',
      description:
          'Connect with runners worldwide. Join teams and compete together on the leaderboards',
      centerColor: const Color(0xFFFF7A9F),
      edgeColor: const Color(0xFF7A1F3D),
    ),
    OnboardingFeature(
      icon: Icons.emoji_events_outlined,
      title: 'Achievements',
      description:
          'Earn rewards and unlock exclusive achievements as you reach new milestones',
      centerColor: const Color(0xFF6BB8FF),
      edgeColor: const Color(0xFF0D3A66),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Scaffold(
      backgroundColor: colors.surfaceBase,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isLight
                  ? [colors.surfaceRaised, colors.surfaceBase]
                  : [Colors.black, colors.surfaceBase],
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Logo
              Icon(Icons.directions_run, color: colors.textPrimary, size: 40),

              const SizedBox(height: 40),

              // Swipable cards
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _features.length,
                  itemBuilder: (context, index) {
                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        double value = 1.0;
                        double activePercent = 1.0;
                        if (_pageController.position.haveDimensions) {
                          final diff = (_pageController.page! - index);
                          value = diff;
                          value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
                          activePercent = (1.0 - diff.abs()).clamp(0.0, 1.0);
                        }
                        return Center(
                          child: SizedBox(
                            height: Curves.easeInOut.transform(value) * 480,
                            child: _buildFeatureCard(
                              _features[index],
                              activePercent: activePercent,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 40),

              // Tagline
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Fitness management,\nreimagined for you',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Join the Trainer Tracker',
                style: TextStyle(color: colors.textSecondary, fontSize: 15),
              ),

              const SizedBox(height: 40),

              // Get Started Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _completeOnboarding,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accentPrimary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Let's Get Started",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    OnboardingFeature feature, {
    required double activePercent,
  }) {
    // Make the centered card glow strongest; off-center cards become subtler.
    final double glowStrength = Curves.easeOut.transform(activePercent);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double cardRadius = 32;
          const double itemClipRadius = 48;

          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(itemClipRadius),
              // Clip the glow to this PageView item so it doesn't bleed into neighbors.
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  // The actual card
                  Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.98,
                      heightFactor: 0.92,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(cardRadius),
                          border: Border.all(
                            color: feature.centerColor.withValues(
                              alpha: 0.35 + (0.35 * glowStrength),
                            ),
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(cardRadius),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Card base gradient
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: Alignment.center,
                                    radius: 0.85,
                                    colors: [
                                      feature.centerColor,
                                      Color.lerp(
                                        feature.centerColor,
                                        feature.edgeColor,
                                        0.5,
                                      )!,
                                      feature.edgeColor,
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                ),
                              ),

                              // Subtle inner glow (lit-from-within highlight)
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: Alignment.topCenter,
                                    radius: 1.2,
                                    colors: [
                                      Colors.white.withValues(
                                        alpha: 0.08 * glowStrength,
                                      ),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),

                              // Content
                              Padding(
                                padding: const EdgeInsets.all(26),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Concentric circles with icon
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: SizedBox(
                                          width: 170,
                                          height: 170,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              // Outermost ripple
                                              Container(
                                                width: 170,
                                                height: 170,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.1),
                                                    width: 1,
                                                  ),
                                                ),
                                              ),
                                              // Second ripple
                                              Container(
                                                width: 130,
                                                height: 130,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.05),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withValues(
                                                          alpha: 0.12,
                                                        ),
                                                    width: 1,
                                                  ),
                                                ),
                                              ),
                                              // Third ripple
                                              Container(
                                                width: 95,
                                                height: 95,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.08),
                                                ),
                                              ),
                                              // Icon background circle
                                              Container(
                                                width: 68,
                                                height: 68,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  feature.icon,
                                                  size: 32,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 22),
                                    // Title
                                    Text(
                                      feature.title,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 25,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    // Description
                                    Flexible(
                                      child: Text(
                                        feature.description,
                                        textAlign: TextAlign.center,
                                        maxLines: 4,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.92,
                                          ),
                                          fontSize: 15,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Very light grain overlay (subtle, but adds "premium" texture)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Opacity(
                                    opacity: 0.055 * glowStrength,
                                    child: CustomPaint(
                                      painter: _NoisePainter(
                                        seed: feature.title.hashCode,
                                        densityPerPixel: 0.002,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  const _NoisePainter({required this.seed, required this.densityPerPixel});

  /// Use a stable seed so the grain doesn't "crawl" frame-to-frame.
  final int seed;

  /// Dots per pixel; keep tiny (e.g. 0.001–0.003).
  final double densityPerPixel;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final random = math.Random(seed);
    final area = size.width * size.height;
    final dotCount = (area * densityPerPixel).round().clamp(120, 1200);

    // Slightly vary dot luminance to mimic film grain.
    for (int i = 0; i < dotCount; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final isLight = random.nextBool();
      final alpha = 0.12 + (random.nextDouble() * 0.22);
      final paint = Paint()
        ..color = (isLight ? Colors.white : Colors.black).withValues(
          alpha: alpha,
        );

      // Mix of 1px squares + tiny circles looks closer to "grain" than circles alone.
      if (random.nextDouble() < 0.65) {
        canvas.drawRect(Rect.fromLTWH(dx, dy, 1, 1), paint);
      } else {
        canvas.drawCircle(Offset(dx, dy), 0.55, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) {
    return seed != oldDelegate.seed ||
        densityPerPixel != oldDelegate.densityPerPixel;
  }
}

/// Data class for onboarding feature card
class OnboardingFeature {
  final IconData icon;
  final String title;
  final String description;
  final Color centerColor;
  final Color edgeColor;

  OnboardingFeature({
    required this.icon,
    required this.title,
    required this.description,
    required this.centerColor,
    required this.edgeColor,
  });
}
