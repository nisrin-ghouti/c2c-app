import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../../../main.dart' show supabase;
import '../../data/datasources/matches_remote_data_source.dart';
import '../../data/repositories/matches_repository_impl.dart';
import '../../domain/repositories/matches_repository.dart';
import '../../domain/usecases/get_match_candidates.dart';
import '../../domain/usecases/score_and_sort_candidates.dart';

final _supabaseClientProvider = Provider<SupabaseClient>((ref) => supabase);

final _matchesRemoteDataSourceProvider = Provider<MatchesRemoteDataSource>((
  ref,
) {
  return MatchesRemoteDataSource(ref.watch(_supabaseClientProvider));
});

final matchesRepositoryProvider = Provider<MatchesRepository>((ref) {
  return MatchesRepositoryImpl(ref.watch(_matchesRemoteDataSourceProvider));
});

final getMatchCandidatesProvider = Provider((ref) {
  return GetMatchCandidates(
    ref.watch(matchesRepositoryProvider),
    const ScoreAndSortCandidates(),
  );
});
