import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around the raw Supabase table calls the roles feature needs.
/// Only file in the feature allowed to reference `supabase_flutter` types
/// directly — `RolesRepositoryImpl` maps everything to domain entities.
class RolesRemoteDataSource {
  const RolesRemoteDataSource(this._client);

  final SupabaseClient _client;

  String get _currentUserId => _client.auth.currentUser!.id;

  Future<List<String>> getMyRoles() async {
    final rows = await _client
        .from('user_roles')
        .select('role')
        .eq('user_id', _currentUserId);
    return List<Map<String, dynamic>>.from(
      rows,
    ).map((r) => r['role'] as String).toList();
  }

  Future<bool> getIsSuperAdmin() async {
    final row = await _client
        .from('profiles')
        .select('is_super_admin')
        .eq('id', _currentUserId)
        .single();
    return row['is_super_admin'] as bool? ?? false;
  }

  Future<bool> getHasEventAccess(String eventId) async {
    final rows = await _client
        .from('host_event_access')
        .select('event_id')
        .eq('event_id', eventId)
        .eq('host_user_id', _currentUserId);
    return (rows as List).isNotEmpty;
  }

  Future<bool> getIsStudentEligible() async {
    return await _client.rpc(
          'is_student_eligible',
          params: {'_user_id': _currentUserId},
        )
        as bool;
  }
}
