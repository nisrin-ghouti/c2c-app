import 'gender.dart';

/// A user's row from `public.profiles`, trimmed to the fields the auth,
/// onboarding, and profile-tab flows need. Deliberately independent of
/// Supabase types — the data layer maps to/from this.
class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    this.email,
    this.faculties = const [],
    this.fieldsOfStudy = const [],
    this.degree,
    this.gender,
    this.year,
    this.bio,
    this.avatarUrl,
    this.studentId,
    this.avatarHue = 220,
    this.hobbies = const [],
    this.interests = const [],
    this.languages = const [],
    this.bannedAt,
  });

  final String id;
  final String fullName;
  final String? email;

  /// Faculties the student belongs to. Multi-value; may be empty.
  final List<String> faculties;

  /// Fields of study / majors. Multi-value; at least one is required for the
  /// profile to count as complete (see [isComplete]).
  final List<String> fieldsOfStudy;

  final String? degree;
  final Gender? gender;
  final int? year;
  final String? bio;
  final String? avatarUrl;

  /// Permanent 10-digit ID the student reads out to a host when their QR
  /// can't be scanned. Assigned server-side and immutable.
  final String? studentId;
  final int avatarHue;
  final List<String> hobbies;
  final List<String> interests;
  final List<String> languages;
  final DateTime? bannedAt;

  bool get isBanned => bannedAt != null;

  /// Convenience single-value accessors for the (legacy) UI spots that only
  /// show one value — the first selected entry, or null when none.
  String? get faculty => faculties.isEmpty ? null : faculties.first;
  String? get fieldOfStudy =>
      fieldsOfStudy.isEmpty ? null : fieldsOfStudy.first;

  /// Whether [fullName] carries both a first and a last name.
  ///
  /// The schema has only `full_name`, so both mandatory name fields are stored
  /// in it and "last name present" means a second word — the same split
  /// `CompleteProfileScreen`/`EditProfileScreen` use to prefill their two
  /// inputs, read back.
  bool get hasFirstAndLastName {
    final parts = fullName.trim().split(RegExp(r'\s+'))
      ..removeWhere((part) => part.isEmpty);
    return parts.length >= 2;
  }

  /// A profile is "complete" (may leave the mandatory Complete-Profile gate)
  /// once every mandatory field is on file: first and last name, field of
  /// study, faculty, degree level, year of study and gender.
  ///
  /// This is the single rule the router's gate, the Complete-Profile screen
  /// and the Edit-Profile screen all answer to, so none of them can disagree
  /// about what "complete" means. Tightening it (it used to be name + field of
  /// study only) means an account saved under the old rule now counts as
  /// incomplete and is routed back through Complete Profile once — by design:
  /// these fields are mandatory for existing users too.
  bool get isComplete =>
      hasFirstAndLastName &&
      fieldsOfStudy.isNotEmpty &&
      faculties.isNotEmpty &&
      (degree?.trim().isNotEmpty ?? false) &&
      year != null &&
      gender != null;
}
