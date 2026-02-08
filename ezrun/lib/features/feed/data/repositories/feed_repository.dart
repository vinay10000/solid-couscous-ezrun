import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/feed_post.dart';

class FeedRepository {
  final SupabaseClient _supabase;

  FeedRepository(this._supabase);

  Future<List<FeedPost>> fetchExplore({int limit = 20, int offset = 0}) async {
    try {
      final res = await _supabase.rpc(
        'ezrun_feed_explore',
        params: {'p_limit': limit, 'p_offset': offset},
      );
      final list = (res as List).cast<Map<String, dynamic>>();
      return list.map(FeedPost.fromRpc).toList(growable: false);
    } on PostgrestException catch (e) {
      // If PostgREST schema cache isn't refreshed yet, fall back to table queries.
      if (e.code == 'PGRST202') {
        return _fetchExploreFallback(limit: limit, offset: offset);
      }
      rethrow;
    }
  }

  Future<List<FeedPost>> fetchFollowing({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final res = await _supabase.rpc(
        'ezrun_feed_following',
        params: {'p_limit': limit, 'p_offset': offset},
      );
      final list = (res as List).cast<Map<String, dynamic>>();
      return list.map(FeedPost.fromRpc).toList(growable: false);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST202') {
        return _fetchFollowingFallback(limit: limit, offset: offset);
      }
      rethrow;
    }
  }

  Future<List<FeedPost>> _fetchExploreFallback({
    required int limit,
    required int offset,
  }) async {
    final rows = await _supabase
        .from('ezrun_posts')
        .select(
          'id, user_id, image_url, caption, created_at, user:users!ezrun_posts_user_id_fkey(name, profile_pic, email)',
        )
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return _mapAndEnrichPosts((rows as List).cast<Map<String, dynamic>>());
  }

  Future<List<FeedPost>> _fetchFollowingFallback({
    required int limit,
    required int offset,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final followRows = await _supabase
        .from('ezrun_follows')
        .select('following_id')
        .eq('follower_id', user.id);

    final followingIds = (followRows as List)
        .map((e) => (e as Map)['following_id'] as String)
        .toList(growable: false);

    if (followingIds.isEmpty) return const [];

    final rows = await _supabase
        .from('ezrun_posts')
        .select(
          'id, user_id, image_url, caption, created_at, user:users!ezrun_posts_user_id_fkey(name, profile_pic, email)',
        )
        .inFilter('user_id', followingIds)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return _mapAndEnrichPosts((rows as List).cast<Map<String, dynamic>>());
  }

  Future<List<FeedPost>> _mapAndEnrichPosts(
    List<Map<String, dynamic>> rows,
  ) async {
    final user = _supabase.auth.currentUser;
    final currentUserId = user?.id;

    if (rows.isEmpty) return const [];

    final postIds = rows.map((r) => r['id'] as String).toList(growable: false);

    final likeRows = await _supabase
        .from('ezrun_post_likes')
        .select('post_id, user_id')
        .inFilter('post_id', postIds);

    final commentRows = await _supabase
        .from('ezrun_post_comments')
        .select('post_id')
        .inFilter('post_id', postIds);

    final likeCountByPost = <String, int>{};
    final likedByMe = <String, bool>{};

    for (final raw in (likeRows as List)) {
      final row = (raw as Map).cast<String, dynamic>();
      final postId = row['post_id'] as String;
      likeCountByPost[postId] = (likeCountByPost[postId] ?? 0) + 1;
      if (currentUserId != null && row['user_id'] == currentUserId) {
        likedByMe[postId] = true;
      }
    }

    final commentCountByPost = <String, int>{};
    for (final raw in (commentRows as List)) {
      final row = (raw as Map).cast<String, dynamic>();
      final postId = row['post_id'] as String;
      commentCountByPost[postId] = (commentCountByPost[postId] ?? 0) + 1;
    }

    return rows
        .map((r) {
          final userMap = (r['user'] as Map?)?.cast<String, dynamic>();
          final name =
              (userMap?['name'] as String?) ??
              ((userMap?['email'] as String?)?.split('@').first ?? 'Runner');
          final profilePic = userMap?['profile_pic'] as String?;

          final postId = r['id'] as String;

          return FeedPost(
            postId: postId,
            userId: r['user_id'] as String,
            username: name,
            profilePic: profilePic,
            imageUrl: r['image_url'] as String?,
            caption: r['caption'] as String?,
            createdAt: DateTime.parse(r['created_at'] as String),
            likeCount: likeCountByPost[postId] ?? 0,
            commentCount: commentCountByPost[postId] ?? 0,
            isLiked: likedByMe[postId] ?? false,
          );
        })
        .toList(growable: false);
  }

  Future<void> likePost(String postId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _supabase.from('ezrun_post_likes').insert({
      'post_id': postId,
      'user_id': user.id,
    });
  }

  Future<void> unlikePost(String postId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _supabase
        .from('ezrun_post_likes')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', user.id);
  }

  Future<void> addComment(String postId, String body) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final trimmed = body.trim();
    if (trimmed.isEmpty) return;

    await _supabase.from('ezrun_post_comments').insert({
      'post_id': postId,
      'user_id': user.id,
      'body': trimmed,
    });
  }

  Future<void> createPost({String? imageUrl, String? caption}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final trimmedCaption = caption?.trim();

    await _supabase.from('ezrun_posts').insert({
      'user_id': user.id,
      'image_url': imageUrl,
      'caption': (trimmedCaption == null || trimmedCaption.isEmpty)
          ? null
          : trimmedCaption,
    });
  }

  Future<List<Map<String, dynamic>>> fetchComments(String postId) async {
    final rows = await _supabase
        .from('ezrun_post_comments')
        .select(
          'id, body, created_at, user_id, users:users!ezrun_post_comments_user_id_fkey(name, profile_pic, email)',
        )
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    return (rows as List).cast<Map<String, dynamic>>();
  }
}
