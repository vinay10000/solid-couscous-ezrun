class FeedPost {
  final String postId;
  final String userId;
  final String username;
  final String? profilePic;
  final String? imageUrl;
  final String? caption;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final bool isLiked;

  const FeedPost({
    required this.postId,
    required this.userId,
    required this.username,
    required this.profilePic,
    required this.imageUrl,
    required this.caption,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
  });

  factory FeedPost.fromRpc(Map<String, dynamic> json) {
    return FeedPost(
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      username: (json['username'] as String?) ?? 'Runner',
      profilePic: json['profile_pic'] as String?,
      imageUrl: json['image_url'] as String?,
      caption: json['caption'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      isLiked: (json['is_liked'] as bool?) ?? false,
    );
  }
}
