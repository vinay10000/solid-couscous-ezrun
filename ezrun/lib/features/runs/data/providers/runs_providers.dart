import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/run_entity.dart';
import '../repositories/runs_repository.dart';
import '../../../profile/data/providers/level_providers.dart';

final runsRepositoryProvider = Provider<RunsRepository>((ref) {
  final levelRepo = ref.watch(levelRepositoryProvider);
  return RunsRepository(Supabase.instance.client, levelRepo);
});

/// Current user's runs (most recent first).
///
/// NOTE: Not `autoDispose` so the runs are prefetched/cached on app start and
/// instantly available when the My Runs sheet is opened.
final myRunsProvider = FutureProvider<List<RunEntity>>((ref) async {
  final repo = ref.watch(runsRepositoryProvider);
  return repo.fetchMyRuns();
});

/// Realtime stream of the current user's runs.
final myRunsStreamProvider = StreamProvider<List<RunEntity>>((ref) {
  final repo = ref.watch(runsRepositoryProvider);
  return repo.watchMyRuns();
});
