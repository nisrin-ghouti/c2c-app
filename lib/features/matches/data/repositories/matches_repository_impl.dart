import '../../../auth/domain/entities/gender.dart';
import '../../domain/entities/match_candidate.dart';
import '../../domain/entities/my_profile_traits.dart';
import '../../domain/repositories/matches_repository.dart';
import '../datasources/matches_remote_data_source.dart';

class MatchesRepositoryImpl implements MatchesRepository {
  MatchesRepositoryImpl(this._remote);

  final MatchesRemoteDataSource _remote;

  List<String> _stringList(dynamic value) =>
      (value as List?)?.cast<String>() ?? const [];

  /// Prefers the multi-value array column, falling back to the single legacy
  /// column (as a one-item list). The single columns are an inconsistent mirror
  /// — some profiles have data only in the array — so the array wins.
  List<String> _multiValue(dynamic arrayValue, dynamic legacyValue) {
    final array = _stringList(
      arrayValue,
    ).where((v) => v.trim().isNotEmpty).toList();
    if (array.isNotEmpty) return array;
    final legacy = legacyValue as String?;
    return (legacy != null && legacy.trim().isNotEmpty) ? [legacy] : const [];
  }

  @override
  Future<MyProfileTraits> getMyProfileTraits() async {
    final row = await _remote.getMyProfile();
    return MyProfileTraits(
      faculty: row['faculty'] as String?,
      fieldOfStudy: row['field_of_study'] as String?,
      year: row['year'] as int?,
      hobbies: _stringList(row['hobbies']),
      interests: _stringList(row['interests']),
      languages: _stringList(row['languages']),
    );
  }

  @override
  Future<List<MatchCandidate>> getCandidates() async {
    final rows = await _remote.getOtherStudents();
    return rows.map((row) {
      return MatchCandidate(
        id: row['id'] as String,
        fullName: (row['full_name'] as String?) ?? '',
        avatarHue: (row['avatar_hue'] as int?) ?? 220,
        faculty: row['faculty'] as String?,
        fieldOfStudy: row['field_of_study'] as String?,
        faculties: _multiValue(row['faculties'], row['faculty']),
        fieldsOfStudy: _multiValue(
          row['fields_of_study'],
          row['field_of_study'],
        ),
        degree: row['degree'] as String?,
        year: row['year'] as int?,
        gender: Gender.fromDbValue(row['gender'] as String?),
        bio: row['bio'] as String?,
        avatarUrl: row['avatar_url'] as String?,
        hobbies: _stringList(row['hobbies']),
        interests: _stringList(row['interests']),
        languages: _stringList(row['languages']),
      );
    }).toList();
  }
}
