import '../entities/student_preview.dart';

/// The seam between the home dashboard's domain/presentation layers and
/// Supabase. See `HomeRemoteDataSource` for the actual table/RPC calls.
abstract interface class HomeRepository {
  Future<String> getMyDisplayName();

  Future<int> getMyPoints();

  Future<int> getUnreadNotificationCount();

  /// Most-recently-joined students, excluding the current user.
  Future<List<StudentPreview>> getNewStudents({int limit = 6});
}
