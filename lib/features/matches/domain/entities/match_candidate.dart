import '../../../../core/utils/initials.dart';
import '../../../auth/domain/entities/gender.dart';

/// A fellow student shown on the Matches tab, already scored against the
/// viewer's own profile (see `ScoreAndSortCandidates`).
class MatchCandidate {
  const MatchCandidate({
    required this.id,
    required this.fullName,
    required this.avatarHue,
    this.faculty,
    this.fieldOfStudy,
    this.faculties = const [],
    this.fieldsOfStudy = const [],
    this.degree,
    this.year,
    this.gender,
    this.bio,
    this.avatarUrl,
    this.hobbies = const [],
    this.interests = const [],
    this.languages = const [],
    this.compatibilityPercent = 0,
  });

  final String id;
  final String fullName;
  final int avatarHue;

  /// Single mirrored values (kept for scoring/filtering/card display).
  final String? faculty;
  final String? fieldOfStudy;

  /// Full multi-value lists — the reliable source (the single columns above
  /// are an inconsistently-populated mirror), used by the detailed profile.
  final List<String> faculties;
  final List<String> fieldsOfStudy;

  final String? degree;
  final int? year;
  final Gender? gender;
  final String? bio;
  final String? avatarUrl;
  final List<String> hobbies;
  final List<String> interests;
  final List<String> languages;

  /// 0-100, normalized — see `ScoreAndSortCandidates`.
  final int compatibilityPercent;

  String get initials => initialsOf(fullName);

  /// Hobbies and interests are still two separate columns server-side (a
  /// legacy split the profile-edit screens no longer expose — see
  /// `Profile.hobbies`/`Profile.interests`), so anywhere the app treats
  /// "interests" as one merged field reads this union instead of either
  /// list alone.
  Set<String> get mergedInterests => {...hobbies, ...interests};

  /// The faculties to match/filter against — prefers the full list, falling
  /// back to the single mirrored value for older/partial rows.
  List<String> get facultyValues =>
      faculties.isNotEmpty ? faculties : [?faculty];

  List<String> get fieldOfStudyValues =>
      fieldsOfStudy.isNotEmpty ? fieldsOfStudy : [?fieldOfStudy];

  MatchCandidate copyWith({int? compatibilityPercent}) {
    return MatchCandidate(
      id: id,
      fullName: fullName,
      avatarHue: avatarHue,
      faculty: faculty,
      fieldOfStudy: fieldOfStudy,
      faculties: faculties,
      fieldsOfStudy: fieldsOfStudy,
      degree: degree,
      year: year,
      gender: gender,
      bio: bio,
      avatarUrl: avatarUrl,
      hobbies: hobbies,
      interests: interests,
      languages: languages,
      compatibilityPercent: compatibilityPercent ?? this.compatibilityPercent,
    );
  }
}
