import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/match_candidate.dart';
import '../providers/matches_providers.dart';

/// The scored/sorted candidate list shown on the Matches tab.
final matchCandidatesProvider =
    FutureProvider.autoDispose<List<MatchCandidate>>((ref) {
      return ref.watch(getMatchCandidatesProvider)();
    });
