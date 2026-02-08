import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileSocialCounts {
  final int posts;
  final int followers;
  final int following;

  const ProfileSocialCounts({
    required this.posts,
    required this.followers,
    required this.following,
  });

  factory ProfileSocialCounts.fromRpc(Map<String, dynamic> json) {
    return ProfileSocialCounts(
      posts: (json['posts_count'] as num?)?.toInt() ?? 0,
      followers: (json['followers_count'] as num?)?.toInt() ?? 0,
      following: (json['following_count'] as num?)?.toInt() ?? 0,
    );
  }
}

enum FollowListType { followers, following }

class ProfileSocialRepository {
  final SupabaseClient _supabase;
  ProfileSocialRepository(this._supabase);

  Future<ProfileSocialCounts> fetchCounts(String userId) async {
    final res = await _supabase.rpc(
      'ezrun_profile_counts',
      params: {'p_user_id': userId},
    );

    // PostgREST returns a single row as a list with one map for set-returning funcs
    if (res is List && res.isNotEmpty) {
      return ProfileSocialCounts.fromRpc(
        (res.first as Map).cast<String, dynamic>(),
      );
    }
    if (res is Map) {
      return ProfileSocialCounts.fromRpc(res.cast<String, dynamic>());
    }
    return const ProfileSocialCounts(posts: 0, followers: 0, following: 0);
  }

  Future<List<Map<String, dynamic>>> fetchFollowList({
    required String userId,
    required FollowListType type,
  }) async {
    switch (type) {
      case FollowListType.followers:
        final rows = await _supabase
            .from('ezrun_follows')
            .select(
              'follower_id, user:users!ezrun_follows_follower_id_fkey(id, name, email, profile_pic)',
            )
            .eq('following_id', userId)
            .order('created_at', ascending: false);

        return (rows as List).cast<Map<String, dynamic>>();
      case FollowListType.following:
        final rows = await _supabase
            .from('ezrun_follows')
            .select(
              'following_id, user:users!ezrun_follows_following_id_fkey(id, name, email, profile_pic)',
            )
            .eq('follower_id', userId)
            .order('created_at', ascending: false);

        return (rows as List).cast<Map<String, dynamic>>();
    }
  }

  Future<bool> isFollowing(String targetUserId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    if (user.id == targetUserId) return false;

    final rows = await _supabase
        .from('ezrun_follows')
        .select('follower_id')
        .eq('follower_id', user.id)
        .eq('following_id', targetUserId)
        .limit(1);

    return (rows as List).isNotEmpty;
  }

  Future<void> follow(String targetUserId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    if (user.id == targetUserId) return;

    await followOrRequest(targetUserId);
  }

  Future<void> followOrRequest(String targetUserId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    if (user.id == targetUserId) return;

    final isPrivate = await _isUserPrivate(targetUserId);
    if (isPrivate) {
      await _supabase.from('ezrun_follow_requests').insert({
        'requester_id': user.id,
        'requested_id': targetUserId,
        'status': 'pending',
      });
      return;
    }

    await _supabase.from('ezrun_follows').insert({
      'follower_id': user.id,
      'following_id': targetUserId,
    });
  }

  Future<bool> hasPendingFollowRequest(String targetUserId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    if (user.id == targetUserId) return false;

    final rows = await _supabase
        .from('ezrun_follow_requests')
        .select('id')
        .eq('requester_id', user.id)
        .eq('requested_id', targetUserId)
        .eq('status', 'pending')
        .limit(1);

    return (rows as List).isNotEmpty;
  }

  Future<bool> _isUserPrivate(String userId) async {
    // If the column isn't present yet (migration not applied), default to public.
    try {
      final rows = await _supabase
          .from('users')
          .select('is_private')
          .eq('id', userId)
          .limit(1);
      final list = (rows as List).cast<Map<String, dynamic>>();
      if (list.isEmpty) return false;
      return (list.first['is_private'] as bool?) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> unfollow(String targetUserId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    if (user.id == targetUserId) return;

    await _supabase
        .from('ezrun_follows')
        .delete()
        .eq('follower_id', user.id)
        .eq('following_id', targetUserId);
  }
}
