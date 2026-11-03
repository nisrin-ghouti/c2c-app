import '../entities/match_candidate.dart';
import '../repositories/matches_repository.dart';
import 'score_and_sort_candidates.dart';

class GetMatchCandidates {
  const GetMatchCandidates(this._repository, this._scoreAndSort);

  final MatchesRepository _repository;
  final ScoreAndSortCandidates _scoreAndSort;

  Future<List<MatchCandidate>> call() async {
    final me = await _repository.getMyProfileTraits();
    final candidates = await _repository.getCandidates();
    return _scoreAndSort(candidates, me);
  }
}
