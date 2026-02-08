import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/feed_post.dart';
import '../repositories/feed_repository.dart';

enum FeedTab { explore, following }

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(Supabase.instance.client);
});

final feedPostsProvider = FutureProvider.autoDispose
    .family<List<FeedPost>, FeedTab>((ref, tab) async {
      final repo = ref.watch(feedRepositoryProvider);
      switch (tab) {
        case FeedTab.explore:
          return repo.fetchExplore();
        case FeedTab.following:
          return repo.fetchFollowing();
      }
    });
