/// Domain entity representing user's level and XP progression.
class UserLevel {
  final int currentLevel;
  final int currentXp;
  final int xpForNextLevel;
  final int totalXp;

  const UserLevel({
    required this.currentLevel,
    required this.currentXp,
    required this.xpForNextLevel,
    required this.totalXp,
  });

  /// Progress towards the next level (0.0 to 1.0).
  double get progressToNextLevel {
    if (xpForNextLevel <= 0) return 1.0;
    return (currentXp / xpForNextLevel).clamp(0.0, 1.0);
  }

  /// Percentage progress (0 to 100).
  int get progressPercentage {
    return (progressToNextLevel * 100).round();
  }

  /// Check if user is at max level.
  bool get isMaxLevel => currentLevel >= LevelSystem.maxLevel;

  factory UserLevel.fromMap(Map<String, dynamic> map) {
    final totalXp = _parseInt(map['total_xp'] ?? map['totalXp'] ?? 0);
    final level = LevelSystem.calculateLevelFromTotalXp(totalXp);
    final xpForCurrentLevel = LevelSystem.calculateXpForLevel(level);
    final xpForNextLevel = LevelSystem.calculateXpForLevel(level + 1);
    final currentXp = totalXp - xpForCurrentLevel;

    return UserLevel(
      currentLevel: level,
      currentXp: currentXp,
      xpForNextLevel: xpForNextLevel - xpForCurrentLevel,
      totalXp: totalXp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'current_level': currentLevel,
      'current_xp': currentXp,
      'xp_for_next_level': xpForNextLevel,
      'total_xp': totalXp,
    };
  }

  static int _parseInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  /// Create initial level (level 1, 0 XP).
  factory UserLevel.initial() {
    return UserLevel(
      currentLevel: 1,
      currentXp: 0,
      xpForNextLevel: LevelSystem.calculateXpForLevel(2),
      totalXp: 0,
    );
  }

  /// Create from total XP.
  factory UserLevel.fromTotalXp(int totalXp) {
    final level = LevelSystem.calculateLevelFromTotalXp(totalXp);
    final xpForCurrentLevel = LevelSystem.calculateXpForLevel(level);
    final xpForNextLevel = LevelSystem.calculateXpForLevel(level + 1);
    final currentXp = totalXp - xpForCurrentLevel;

    return UserLevel(
      currentLevel: level,
      currentXp: currentXp,
      xpForNextLevel: xpForNextLevel - xpForCurrentLevel,
      totalXp: totalXp,
    );
  }

  UserLevel copyWith({
    int? currentLevel,
    int? currentXp,
    int? xpForNextLevel,
    int? totalXp,
  }) {
    return UserLevel(
      currentLevel: currentLevel ?? this.currentLevel,
      currentXp: currentXp ?? this.currentXp,
      xpForNextLevel: xpForNextLevel ?? this.xpForNextLevel,
      totalXp: totalXp ?? this.totalXp,
    );
  }
}

/// Level system configuration and calculation utilities.
class LevelSystem {
  LevelSystem._();

  /// Maximum level a user can reach.
  static const int maxLevel = 100;

  /// Base XP required for level 1 to 2.
  static const int baseXp = 20;

  /// XP earned per completed run.
  static const int xpPerRun = 10;

  /// Growth factor for XP requirements (exponential growth).
  /// Using a moderate growth factor to keep it achievable.
  static const double growthFactor = 1.1;

  /// Calculate XP required to reach a specific level from level 0.
  ///
  /// Formula: Uses exponential growth with a base requirement.
  /// Level 1: 0 XP
  /// Level 2: 20 XP
  /// Level 3: 42 XP (20 + 22)
  /// Level 4: 66 XP (42 + 24)
  /// etc.
  static int calculateXpForLevel(int level) {
    if (level <= 1) return 0;
    if (level > maxLevel) return calculateXpForLevel(maxLevel);

    int totalXp = 0;
    for (int i = 2; i <= level; i++) {
      // XP for level i = baseXp * (growthFactor ^ (i-2))
      final xpForThisLevel = (baseXp * _pow(growthFactor, i - 2)).round();
      totalXp += xpForThisLevel;
    }
    return totalXp;
  }

  /// Calculate current level from total XP.
  static int calculateLevelFromTotalXp(int totalXp) {
    if (totalXp < 0) return 1;

    int level = 1;
    while (level < maxLevel && totalXp >= calculateXpForLevel(level + 1)) {
      level++;
    }
    return level;
  }

  /// Calculate XP required for the next level.
  static int calculateXpForNextLevel(int currentLevel) {
    if (currentLevel >= maxLevel) return 0;
    return calculateXpForLevel(currentLevel + 1) -
        calculateXpForLevel(currentLevel);
  }

  /// Simple power function for calculations.
  static double _pow(double base, int exponent) {
    if (exponent == 0) return 1.0;
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }

  /// Get a list of all level thresholds (for debugging/testing).
  static List<int> getAllLevelThresholds() {
    return List.generate(maxLevel + 1, (index) => calculateXpForLevel(index));
  }

  /// Calculate how many runs needed to reach next level from current XP.
  static int runsToNextLevel(int currentXp, int currentLevel) {
    if (currentLevel >= maxLevel) return 0;
    final xpNeeded = calculateXpForNextLevel(currentLevel);
    final xpInCurrentLevel = currentXp;
    final remainingXp = xpNeeded - xpInCurrentLevel;
    return (remainingXp / xpPerRun).ceil();
  }
}
