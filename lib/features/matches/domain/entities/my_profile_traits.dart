/// The subset of the viewer's own profile needed to score candidates —
/// deliberately separate from the auth feature's `Profile` entity, which
/// doesn't carry hobbies/interests/languages (out of scope there).
class MyProfileTraits {
  const MyProfileTraits({
    this.faculty,
    this.fieldOfStudy,
    this.year,
    this.hobbies = const [],
    this.interests = const [],
    this.languages = const [],
  });

  final String? faculty;
  final String? fieldOfStudy;
  final int? year;
  final List<String> hobbies;
  final List<String> interests;
  final List<String> languages;

  /// See `MatchCandidate.mergedInterests` — same union, same reason.
  Set<String> get mergedInterests => {...hobbies, ...interests};
}
