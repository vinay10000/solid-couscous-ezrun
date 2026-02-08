import 'package:equatable/equatable.dart';

enum AchievementType { milestone, streak, social, performance, special }

class Achievement extends Equatable {
  final String id;
  final String title;
  final String description;
  final String iconAsset;
  final AchievementType type;
  final int? targetValue; // e.g. 10000 (meters), 5 (friends)
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconAsset,
    required this.type,
    this.targetValue,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  Achievement copyWith({bool? isUnlocked, DateTime? unlockedAt}) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      iconAsset: iconAsset,
      type: type,
      targetValue: targetValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    iconAsset,
    type,
    targetValue,
    isUnlocked,
    unlockedAt,
  ];
}
