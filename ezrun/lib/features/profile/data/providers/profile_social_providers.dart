import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/profile_social_repository.dart';

final profileSocialRepositoryProvider = Provider<ProfileSocialRepository>((
  ref,
) {
  return ProfileSocialRepository(Supabase.instance.client);
});

final profileSocialCountsProvider = FutureProvider.autoDispose
    .family<ProfileSocialCounts, String>((ref, userId) async {
      final repo = ref.watch(profileSocialRepositoryProvider);
      return repo.fetchCounts(userId);
    });

final followListProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, ({String userId, FollowListType type})>(
      (ref, args) async {
        final repo = ref.watch(profileSocialRepositoryProvider);
        return repo.fetchFollowList(userId: args.userId, type: args.type);
      },
    );

final isFollowingProvider = FutureProvider.autoDispose.family<bool, String>((
  ref,
  targetUserId,
) async {
  final repo = ref.watch(profileSocialRepositoryProvider);
  return repo.isFollowing(targetUserId);
});

final hasPendingFollowRequestProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, targetUserId) async {
      final repo = ref.watch(profileSocialRepositoryProvider);
      return repo.hasPendingFollowRequest(targetUserId);
    });
