import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around the raw Supabase table/RPC calls the home dashboard
/// needs. Only file in the feature allowed to reference `supabase_flutter`
/// types directly — `HomeRepositoryImpl` maps everything to domain entities.
class HomeRemoteDataSource {
  const HomeRemoteDataSource(this._client);

  final SupabaseClient _client;

  String get currentUserId => _client.auth.currentUser!.id;

  Future<Map<String, dynamic>> getMyProfile() {
    return _client
        .from('profiles')
        .select('full_name')
        .eq('id', currentUserId)
        .single();
  }

  Future<int> getMyPoints() async {
    final result = await _client.rpc('get_my_points');
    return (result as num?)?.toInt() ?? 0;
  }

  Future<int> getUnreadNotificationCount() async {
    final response = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', currentUserId)
        .filter('read_at', 'is', null)
        .count(CountOption.exact);
    return response.count;
  }

  Future<List<Map<String, dynamic>>> getNewStudents({
    required int limit,
  }) async {
    final rows = await _client
        .from('profiles')
        .select('id, full_name, faculty, year, avatar_hue, avatar_url, hobbies')
        .neq('id', currentUserId)
        .filter('deleted_at', 'is', null)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }
}
