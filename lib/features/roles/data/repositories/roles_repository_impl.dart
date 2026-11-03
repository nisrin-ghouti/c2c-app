import '../../domain/entities/user_role.dart';
import '../../domain/repositories/roles_repository.dart';
import '../datasources/roles_remote_data_source.dart';

class RolesRepositoryImpl implements RolesRepository {
  RolesRepositoryImpl(this._remote);

  final RolesRemoteDataSource _remote;

  @override
  Future<Set<UserRole>> myRoles() async {
    final raw = await _remote.getMyRoles();
    return raw.map(_parseRole).whereType<UserRole>().toSet();
  }

  @override
  Future<bool> isSuperAdmin() => _remote.getIsSuperAdmin();

  @override
  Future<bool> hasEventAccess(String eventId) =>
      _remote.getHasEventAccess(eventId);

  @override
  Future<bool> isStudentEligible() => _remote.getIsStudentEligible();

  UserRole? _parseRole(String raw) => switch (raw) {
    'student' => UserRole.student,
    'host' => UserRole.host,
    'admin' => UserRole.admin,
    _ => null,
  };
}
