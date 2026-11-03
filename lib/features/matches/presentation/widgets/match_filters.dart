import '../../../auth/domain/entities/gender.dart';
import '../../domain/entities/match_candidate.dart';

/// The Matches screen's search + filter state, and the pure filtering rule
/// applied on top of the already-scored candidate list.
///
/// Faculty, Field of Study, Language, and Interests are multi-select: an
/// empty set means "no filter on this dimension", a non-empty set matches a
/// candidate who overlaps it on ANY value (OR within the dimension; the
/// dimensions themselves still AND together). Degree, Year, and Gender stay
/// single-select.
class MatchFilters {
  const MatchFilters({
    required this.allLabel,
    this.searchQuery = '',
    this.faculty = const {},
    this.fieldOfStudy = const {},
    this.interests = const {},
    this.language = const {},
    String? degree,
    String? year,
    String? gender,
  }) : degree = degree ?? allLabel,
       year = year ?? allLabel,
       gender = gender ?? allLabel;

  /// The localized "All" chip value — degree/year/gender default to this.
  final String allLabel;
  final String searchQuery;
  final Set<String> faculty;
  final Set<String> fieldOfStudy;
  final Set<String> interests;
  final Set<String> language;
  final String degree;
  final String year;

  /// The selected [Gender.dbValue], or [allLabel] for no filter.
  final String gender;

  MatchFilters copyWith({
    String? searchQuery,
    Set<String>? faculty,
    Set<String>? fieldOfStudy,
    Set<String>? interests,
    Set<String>? language,
    String? degree,
    String? year,
    String? gender,
  }) {
    return MatchFilters(
      allLabel: allLabel,
      searchQuery: searchQuery ?? this.searchQuery,
      faculty: faculty ?? this.faculty,
      fieldOfStudy: fieldOfStudy ?? this.fieldOfStudy,
      interests: interests ?? this.interests,
      language: language ?? this.language,
      degree: degree ?? this.degree,
      year: year ?? this.year,
      gender: gender ?? this.gender,
    );
  }

  bool _matchesYear(int? candidateYear) {
    if (year == allLabel) return true;
    if (candidateYear == null) return false;
    if (year == '+5') return candidateYear >= 5;
    return '$candidateYear' == year;
  }

  static bool _overlaps(
    Set<String> selected,
    Iterable<String> candidateValues,
  ) {
    if (selected.isEmpty) return true;
    return candidateValues.any(selected.contains);
  }

  bool _matchesSearch(MatchCandidate c) {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    final haystack = [
      c.fullName,
      ...c.mergedInterests,
      ...c.languages,
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }

  bool _matchesGender(Gender? candidateGender) {
    if (gender == allLabel) return true;
    return candidateGender?.dbValue == gender;
  }

  List<MatchCandidate> apply(List<MatchCandidate> candidates) {
    return candidates.where((c) {
      if (!_overlaps(faculty, c.facultyValues)) return false;
      if (!_overlaps(fieldOfStudy, c.fieldOfStudyValues)) return false;
      if (degree != allLabel && c.degree != degree) return false;
      if (!_matchesYear(c.year)) return false;
      if (!_matchesGender(c.gender)) return false;
      if (!_overlaps(interests, c.mergedInterests)) return false;
      if (!_overlaps(language, c.languages)) return false;
      if (!_matchesSearch(c)) return false;
      return true;
    }).toList();
  }
}

/// Builds the option list for a single-value field (degree), starting with
/// [allLabel], followed by the distinct values actually present in
/// [candidates] (never a hardcoded guess at what values exist).
List<String> optionsForField(
  List<MatchCandidate> candidates,
  String allLabel,
  String? Function(MatchCandidate) selector,
) {
  final distinct = candidates
      .map(selector)
      .whereType<String>()
      .where((v) => v.isNotEmpty)
      .toSet();
  return [allLabel, ...distinct];
}

/// Builds the option list for a multi-select field (faculty/fieldOfStudy/
/// language/interests) — the distinct values actually present in
/// [candidates], with no `allLabel` sentinel (an empty selection already
/// means "no filter" for these).
List<String> optionsForListField(
  List<MatchCandidate> candidates,
  List<String> Function(MatchCandidate) selector,
) {
  final distinct = <String>{};
  for (final c in candidates) {
    distinct.addAll(selector(c).where((v) => v.isNotEmpty));
  }
  return distinct.toList();
}

/// Gender's option list is the fixed set of values the app collects
/// (Female/Male/Prefer not to say), not derived from who happens to be in
/// [candidates] — unlike faculty/language/etc., which are open admin-curated
/// lists.
List<String> genderOptions(String allLabel) {
  return [
    allLabel,
    Gender.female.dbValue,
    Gender.male.dbValue,
    Gender.undisclosed.dbValue,
  ];
}

List<String> yearOptions(List<MatchCandidate> candidates, String allLabel) {
  final years = candidates.map((c) => c.year).whereType<int>().toSet();
  final options = <String>[allLabel];
  for (final y in [1, 2, 3, 4]) {
    if (years.contains(y)) options.add('$y');
  }
  if (years.any((y) => y >= 5)) options.add('+5');
  return options;
}
