enum AppNotificationType { like, followRequest }

class AppNotification {
  final AppNotificationType type;
  final DateTime createdAt;

  /// The actor (liker / requester)
  final String actorUserId;
  final String actorUsername;
  final String? actorProfilePic;

  /// Like-only
  final String? postId;

  /// Follow-request-only
  final String? followRequestId;

  const AppNotification({
    required this.type,
    required this.createdAt,
    required this.actorUserId,
    required this.actorUsername,
    required this.actorProfilePic,
    this.postId,
    this.followRequestId,
  });
}
