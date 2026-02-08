import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/app_notification.dart';

class NotificationsRepository {
  final SupabaseClient _supabase;
  NotificationsRepository(this._supabase);

  Future<List<AppNotification>> fetchNotifications({int limit = 60}) async {
    final me = _supabase.auth.currentUser;
    if (me == null) throw Exception('Not authenticated');

    final likeNotifs = await _fetchLikeNotifications(me.id, limit: limit);
    final followReqNotifs = await _fetchFollowRequestNotifications(
      me.id,
      limit: limit,
    );

    final all = <AppNotification>[...likeNotifs, ...followReqNotifs];

    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all.take(limit).toList(growable: false);
  }

  Future<void> acceptFollowRequest({
    required String requestId,
    required String requesterId,
  }) async {
    final me = _supabase.auth.currentUser;
    if (me == null) throw Exception('Not authenticated');

    // Mark request accepted
    await _supabase
        .from('ezrun_follow_requests')
        .update({
          'status': 'accepted',
          'acted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId)
        .eq('requested_id', me.id);

    // Create the follow edge (requester -> me)
    await _supabase.from('ezrun_follows').upsert({
      'follower_id': requesterId,
      'following_id': me.id,
    }, onConflict: 'follower_id,following_id');
  }

  Future<void> denyFollowRequest({required String requestId}) async {
    final me = _supabase.auth.currentUser;
    if (me == null) throw Exception('Not authenticated');

    await _supabase
        .from('ezrun_follow_requests')
        .update({
          'status': 'denied',
          'acted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId)
        .eq('requested_id', me.id);
  }

  // -------------------------
  // Internals
  // -------------------------

  Future<List<AppNotification>> _fetchLikeNotifications(
    String myUserId, {
    required int limit,
  }) async {
    // Get my post IDs first (avoids relying on foreign-key constraint names).
    final postRows = await _supabase
        .from('ezrun_posts')
        .select('id')
        .eq('user_id', myUserId)
        .order('created_at', ascending: false);

    final postIds = (postRows as List)
        .map((e) => (e as Map)['id'] as String)
        .toList(growable: false);

    if (postIds.isEmpty) return const [];

    final likeRows = await _supabase
        .from('ezrun_post_likes')
        .select('post_id, user_id, created_at')
        .inFilter('post_id', postIds)
        .order('created_at', ascending: false)
        .limit(limit);

    final likes = (likeRows as List).cast<Map<String, dynamic>>();
    if (likes.isEmpty) return const [];

    final actorIds = likes
        .map((r) => r['user_id'] as String)
        .where((id) => id != myUserId) // don't notify self-likes
        .toSet()
        .toList(growable: false);

    if (actorIds.isEmpty) return const [];

    final usersById = await _fetchUsersById(actorIds);

    return likes
        .where((r) => (r['user_id'] as String) != myUserId)
        .map((r) {
          final actorId = r['user_id'] as String;
          final user = usersById[actorId];
          final username = _displayName(user);
          final createdAt = _parseDateTime(r['created_at']);
          return AppNotification(
            type: AppNotificationType.like,
            createdAt: createdAt,
            actorUserId: actorId,
            actorUsername: username,
            actorProfilePic: user?['profile_pic'] as String?,
            postId: r['post_id'] as String,
          );
        })
        .toList(growable: false);
  }

  Future<List<AppNotification>> _fetchFollowRequestNotifications(
    String myUserId, {
    required int limit,
  }) async {
    final rows = await _supabase
        .from('ezrun_follow_requests')
        .select('id, requester_id, created_at')
        .eq('requested_id', myUserId)
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .limit(limit);

    final list = (rows as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) return const [];

    final actorIds = list
        .map((r) => r['requester_id'] as String)
        .toSet()
        .toList(growable: false);

    final usersById = await _fetchUsersById(actorIds);

    return list
        .map((r) {
          final actorId = r['requester_id'] as String;
          final user = usersById[actorId];
          final username = _displayName(user);
          final createdAt = _parseDateTime(r['created_at']);
          return AppNotification(
            type: AppNotificationType.followRequest,
            createdAt: createdAt,
            actorUserId: actorId,
            actorUsername: username,
            actorProfilePic: user?['profile_pic'] as String?,
            followRequestId: r['id'] as String,
          );
        })
        .toList(growable: false);
  }

  Future<Map<String, Map<String, dynamic>>> _fetchUsersById(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return const {};

    final rows = await _supabase
        .from('users')
        .select('id, name, email, profile_pic')
        .inFilter('id', userIds);

    final list = (rows as List).cast<Map<String, dynamic>>();
    return {for (final u in list) (u['id'] as String): u};
  }

  String _displayName(Map<String, dynamic>? user) {
    if (user == null) return 'Runner';
    final name = (user['name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = (user['email'] as String?)?.trim();
    if (email != null && email.contains('@')) return email.split('@').first;
    return 'Runner';
  }

  DateTime _parseDateTime(Object? raw) {
    if (raw == null) return DateTime.now();
    if (raw is DateTime) return raw;
    if (raw is String) {
      return DateTime.tryParse(raw) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
