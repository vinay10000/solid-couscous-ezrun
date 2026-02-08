/// Domain entity representing a user entry in the leaderboard.
///
/// Contains user information and ranking data for display in leaderboards.
class LeaderboardEntry {
  final String userId;
  final String username;
  final String? profilePic;
  final String? profileColor;
  final int totalXp;
  final int currentLevel;
  final int rank;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.totalXp,
    required this.currentLevel,
    required this.rank,
    this.profilePic,
    this.profileColor,
    this.isCurrentUser = false,
  });

  /// Creates a LeaderboardEntry from a database row map.
  factory LeaderboardEntry.fromMap(
    Map<String, dynamic> map, {
    required int rank,
    bool isCurrentUser = false,
  }) {
    return LeaderboardEntry(
      userId: map['id']?.toString() ?? '',
      username: map['name']?.toString() ?? 'Unknown Runner',
      profilePic: map['profile_pic']?.toString(),
      profileColor: map['profile_color']?.toString() ?? '#00D4FF',
      totalXp: (map['total_xp'] as num?)?.toInt() ?? 0,
      currentLevel: _calculateLevelFromXp(
        (map['total_xp'] as num?)?.toInt() ?? 0,
      ),
      rank: rank,
      isCurrentUser: isCurrentUser,
    );
  }

  /// Calculate level from total XP using the same logic as the level system.
  static int _calculateLevelFromXp(int totalXp) {
    if (totalXp < 20) return 1;
    if (totalXp < 42) return 2;
    if (totalXp < 66) return 3;
    if (totalXp < 92) return 4;
    if (totalXp < 121) return 5;
    return (6 + ((totalXp - 121) ~/ 30)).clamp(1, 100);
  }

  /// Creates a copy with updated properties.
  LeaderboardEntry copyWith({
    String? userId,
    String? username,
    String? profilePic,
    String? profileColor,
    int? totalXp,
    int? currentLevel,
    int? rank,
    bool? isCurrentUser,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      profilePic: profilePic ?? this.profilePic,
      profileColor: profileColor ?? this.profileColor,
      totalXp: totalXp ?? this.totalXp,
      currentLevel: currentLevel ?? this.currentLevel,
      rank: rank ?? this.rank,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }
}
