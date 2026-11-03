import '../../domain/entities/student_preview.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._remote);

  final HomeRemoteDataSource _remote;

  @override
  Future<String> getMyDisplayName() async {
    final profile = await _remote.getMyProfile();
    final fullName = (profile['full_name'] as String?)?.trim() ?? '';
    if (fullName.isEmpty) return '';
    return fullName.split(RegExp(r'\s+')).first;
  }

  @override
  Future<int> getMyPoints() => _remote.getMyPoints();

  @override
  Future<int> getUnreadNotificationCount() =>
      _remote.getUnreadNotificationCount();

  @override
  Future<List<StudentPreview>> getNewStudents({int limit = 6}) async {
    final rows = await _remote.getNewStudents(limit: limit);
    return rows.map((row) {
      return StudentPreview(
        id: row['id'] as String,
        fullName: (row['full_name'] as String?) ?? '',
        avatarHue: (row['avatar_hue'] as int?) ?? 220,
        faculty: row['faculty'] as String?,
        year: row['year'] as int?,
        avatarUrl: row['avatar_url'] as String?,
        hobbies: (row['hobbies'] as List?)?.cast<String>() ?? const [],
      );
    }).toList();
  }
}
