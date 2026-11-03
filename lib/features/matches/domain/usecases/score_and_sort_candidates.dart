import '../entities/match_candidate.dart';
import '../entities/my_profile_traits.dart';

/// Computes a normalized 0-100 compatibility score per candidate:
///   - same faculty: 15
///   - same field of study: 15
///   - shared languages: up to 25, scaled by (shared / my language count)
///   - shared interests (merged hobbies+interests both sides): up to 25,
///     scaled by (shared / my interest count)
///   - same year: 20
///
/// A pure function (no repository dependency, no sorting) — the screen
/// re-sorts the already-scored list by [MatchCandidate.compatibilityPercent]
/// itself so toggling sort direction never needs a re-fetch.
class ScoreAndSortCandidates {
  const ScoreAndSortCandidates();

  List<MatchCandidate> call(
    List<MatchCandidate> candidates,
    MyProfileTraits me,
  ) {
    final myInterests = me.mergedInterests;
    final myLanguages = me.languages.toSet();

    return candidates.map((candidate) {
      double percent = 0;

      if (me.faculty != null && me.faculty == candidate.faculty) percent += 15;
      if (me.fieldOfStudy != null &&
          me.fieldOfStudy == candidate.fieldOfStudy) {
        percent += 15;
      }

      if (myLanguages.isNotEmpty) {
        final shared = myLanguages
            .intersection(candidate.languages.toSet())
            .length;
        percent += 25 * (shared / myLanguages.length);
      }

      if (myInterests.isNotEmpty) {
        final shared = myInterests
            .intersection(candidate.mergedInterests)
            .length;
        percent += 25 * (shared / myInterests.length);
      }

      if (me.year != null && me.year == candidate.year) percent += 20;

      return candidate.copyWith(
        compatibilityPercent: percent.round().clamp(0, 100),
      );
    }).toList();
  }
}
