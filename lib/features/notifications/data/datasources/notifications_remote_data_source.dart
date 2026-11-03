import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around the raw Supabase table calls the notifications
/// feature needs. Only file in the feature allowed to reference
/// `supabase_flutter` types directly. Notification rows are written
/// server-side only (by triggers on `point_transactions`/`chat_messages`/
/// `meeting_proposals` inserts) — this feature only ever reads/marks-read.
class NotificationsRemoteDataSource {
  const NotificationsRemoteDataSource(this._client);

  // Note on the `read_at` writes below: `toUtc()` before `toIso8601String()`
  // is required. A local DateTime serialises without an offset, which Postgres
  // then reads in its own zone (UTC) — so a "mark as read" stamped a time 3
  // hours in the future (the Israel offset). Same trap as
  // `EventsRemoteDataSource.getUpcomingEvents`.

  final SupabaseClient _client;

  String get currentUserId => _client.auth.currentUser!.id;

  Future<List<Map<String, dynamic>>> listMyNotifications() async {
    final rows = await _client
        .from('notifications')
        .select('id, type, data, read_at, created_at')
        .eq('user_id', currentUserId)
        .order('created_at', ascending: false)
        .limit(100);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Just the two event-reminder types, newest first.
  ///
  /// A separate, narrower query rather than reusing [listMyNotifications]
  /// because the caller is the once-a-day reminder popup, which is read on
  /// every app launch and resume. Sharing the full list's provider would keep
  /// that cache alive for the whole session and leave the notification centre
  /// showing a stale list; sharing the query without the provider would pull
  /// 100 rows of unrelated types to find at most a handful.
  ///
  /// Capped low: more than a few reminders can't be due on one day, since a
  /// reminder is only due on its own day (see `pendingEventReminders`).
  Future<List<Map<String, dynamic>>> listMyEventReminders() async {
    final rows = await _client
        .from('notifications')
        .select('id, type, data, read_at, created_at')
        .eq('user_id', currentUserId)
        .inFilter('type', const [
          'event_reminder_tomorrow',
          'event_reminder_today',
        ])
        .order('created_at', ascending: false)
        .limit(20);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<int> getUnreadCount() async {
    final response = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', currentUserId)
        .filter('read_at', 'is', null)
        .count(CountOption.exact);
    return response.count;
  }

  Future<void> markAllAsRead() async {
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', currentUserId)
        .filter('read_at', 'is', null);
  }

  Future<void> markAsRead(List<String> ids) async {
    if (ids.isEmpty) return;
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', currentUserId)
        .inFilter('id', ids);
  }

  Future<void> markAsUnread(List<String> ids) async {
    if (ids.isEmpty) return;
    await _client
        .from('notifications')
        .update({'read_at': null})
        .eq('user_id', currentUserId)
        .inFilter('id', ids);
  }

  Future<void> deleteNotifications(List<String> ids) async {
    if (ids.isEmpty) return;
    await _client
        .from('notifications')
        .delete()
        .eq('user_id', currentUserId)
        .inFilter('id', ids);
  }

  Future<void> deleteAllNotifications() async {
    await _client.from('notifications').delete().eq('user_id', currentUserId);
  }
}
