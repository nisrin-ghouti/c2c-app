import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around the raw Supabase table/RPC/realtime calls the
/// matches feature needs. Only file allowed to reference `supabase_flutter`
/// types directly.
class MatchesRemoteDataSource {
  const MatchesRemoteDataSource(this._client);

  final SupabaseClient _client;

  String get currentUserId => _client.auth.currentUser!.id;

  Future<Map<String, dynamic>> getMyProfile() {
    return _client
        .from('profiles')
        .select('faculty, field_of_study, year, hobbies, interests, languages')
        .eq('id', currentUserId)
        .single();
  }

  /// Candidates via RPC (not a raw table select) so it can filter out
  /// Admin/Host-only accounts server-side — `list_match_candidates` only
  /// returns profiles `is_student_eligible` considers a student.
  Future<List<Map<String, dynamic>>> getOtherStudents() async {
    final result = await _client.rpc('list_match_candidates');
    return List<Map<String, dynamic>>.from(result as List? ?? const []);
  }
}
