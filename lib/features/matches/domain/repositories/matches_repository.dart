import '../entities/match_candidate.dart';
import '../entities/my_profile_traits.dart';

abstract interface class MatchesRepository {
  Future<MyProfileTraits> getMyProfileTraits();

  /// Other students, unscored — `ScoreAndSortCandidates` applies the
  /// business rule on top of this.
  Future<List<MatchCandidate>> getCandidates();
}
