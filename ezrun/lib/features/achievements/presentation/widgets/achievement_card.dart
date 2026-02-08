import 'package:flutter/material.dart';
import '../../domain/entities/achievement_entity.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const AchievementCard({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    final titleColor = achievement.isUnlocked ? null : Colors.grey;
    final descColor = achievement.isUnlocked
        ? Colors.grey[700]
        : Colors.grey[400];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Bulletproof against tiny RenderFlex overflows (text scaling/pixel rounding)
        // by scaling the whole card down if needed.
        final iconSize = (constraints.maxWidth * 0.78).clamp(36.0, 64.0);

        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: SizedBox(
            width: constraints.maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AchievementIconCircle(
                  iconAsset: achievement.iconAsset,
                  isUnlocked: achievement.isUnlocked,
                  size: iconSize,
                ),
                const SizedBox(height: 6),
                Text(
                  achievement.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: titleColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: descColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AchievementIconCircle extends StatelessWidget {
  final String iconAsset;
  final bool isUnlocked;
  final double size;

  const _AchievementIconCircle({
    required this.iconAsset,
    required this.isUnlocked,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      iconAsset,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Helpful when debugging missing assets on device builds.
        // ignore: avoid_print
        print('Achievement icon failed to load: $iconAsset ($error)');
        // Never show a Placeholder() (it matches the screenshot "X" box).
        return const ColoredBox(
          color: Color(0x22000000),
          child: Center(
            child: Icon(
              Icons.emoji_events_outlined,
              size: 28,
              color: Colors.white70,
            ),
          ),
        );
      },
    );

    return SizedBox.square(
      dimension: size,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: ClipOval(
          child: isUnlocked
              ? image
              : ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.grey,
                    BlendMode.saturation,
                  ),
                  child: image,
                ),
        ),
      ),
    );
  }
}
