import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around the raw Supabase table/RPC calls the points/
/// leaderboard feature needs. Only file allowed to reference
/// `supabase_flutter` types directly.
class PointsRemoteDataSource {
  const PointsRemoteDataSource(this._client);

  final SupabaseClient _client;

  String get currentUserId => _client.auth.currentUser!.id;

  Future<int> getMyPoints() async {
    final result = await _client.rpc('get_my_points');
    return (result as num?)?.toInt() ?? 0;
  }

  Future<List<Map<String, dynamic>>> getRecentTransactions({
    required int limit,
  }) async {
    final rows = await _client
        .from('point_transactions')
        .select('id, amount, reason, created_at')
        .eq('user_id', currentUserId)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> getMonthlyLeaderboard({
    required int limit,
  }) async {
    final result = await _client.rpc(
      'get_monthly_leaderboard',
      params: {'_limit': limit},
    );
    return List<Map<String, dynamic>>.from(result as List);
  }

  Future<Map<String, dynamic>?> getMyMonthlyRank() async {
    final result = await _client.rpc('get_my_monthly_rank');
    if (result == null) return null;
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>?> getChampionsAnnouncement() async {
    final result = await _client.rpc('get_champions_announcement');
    if (result == null) return null;
    return Map<String, dynamic>.from(result as Map);
  }

  Future<void> markChampionsAnnouncementSeen({
    required bool general,
    required bool winner,
  }) async {
    await _client.rpc(
      'mark_champions_announcement_seen',
      params: {'_general': general, '_winner': winner},
    );
  }
}
