import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around the raw Supabase table/RPC/realtime calls the chat
/// feature needs. Only file in the feature allowed to reference
/// `supabase_flutter` types directly.
class ChatRemoteDataSource {
  const ChatRemoteDataSource(this._client);

  final SupabaseClient _client;

  String get currentUserId => _client.auth.currentUser!.id;

  Future<List<Map<String, dynamic>>> listMyChats() async {
    final result = await _client.rpc('list_my_chats');
    return List<Map<String, dynamic>>.from(result as List);
  }

  Future<void> markChatRead(String chatId) async {
    await _client.rpc('mark_chat_read', params: {'_chat_id': chatId});
  }

  Future<String> getOrCreateChat(String otherUserId) async {
    final result = await _client.rpc(
      'get_or_create_chat',
      params: {'_other_user_id': otherUserId},
    );
    return result as String;
  }

  /// Realtime feed of a chat's messages, oldest first — the whole set re-emits
  /// on every change, same pattern as `MatchesRemoteDataSource.watchSession`.
  ///
  /// `ascending: true` is explicit on purpose: Supabase's `.order()` defaults
  /// to DESCENDING, which silently returned newest-first here.
  Stream<List<Map<String, dynamic>>> watchMessages(String chatId) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true);
  }

  Future<Map<String, dynamic>> sendMessage(String chatId, String body) async {
    final result = await _client.rpc(
      'send_message',
      params: {'_chat_id': chatId, '_body': body},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<void> blockUser(String userId) async {
    await _client.rpc('block_user', params: {'_user_id': userId});
  }

  Future<void> unblockUser(String userId) async {
    await _client.rpc('unblock_user', params: {'_user_id': userId});
  }

  Future<bool> haveIBlocked(String otherUserId) async {
    final rows = await _client
        .from('blocks')
        .select('blocker_id')
        .eq('blocker_id', currentUserId)
        .eq('blocked_id', otherUserId);
    return (rows as List).isNotEmpty;
  }

  Future<Map<String, dynamic>> proposeMeeting(
    String chatId,
    DateTime scheduledAt,
    DateTime endsAt,
    String? location,
    String? notes,
  ) async {
    final result = await _client.rpc(
      'propose_meeting',
      params: {
        '_chat_id': chatId,
        // toUtc() first: the pickers produce a LOCAL DateTime, and
        // toIso8601String() emits no offset for one, so Postgres would parse
        // it in the server's zone (UTC) and store the wall-clock time as if
        // it were UTC — three hours off for an Israeli campus, which then
        // skews every server-side rule (daily limits, start/end windows).
        '_scheduled_at': scheduledAt.toUtc().toIso8601String(),
        '_ends_at': endsAt.toUtc().toIso8601String(),
        '_location': location,
        '_notes': notes,
      },
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> respondToProposal(
    String proposalId,
    bool accept,
  ) async {
    final result = await _client.rpc(
      'respond_to_meeting_proposal',
      params: {'_proposal_id': proposalId, '_accept': accept},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  /// Realtime feed of one meeting proposal's row.
  ///
  /// A stream rather than a one-shot read because the row is written by the
  /// OTHER participant: the proposer's chat card has to follow an acceptance
  /// it didn't trigger, and nothing in the proposer's app knows when that
  /// happens. Same pattern as [watchMessages] and
  /// `ScheduledMeetingRepository.watchCheckins`.
  ///
  /// Emits a single-element list, or an empty one if the row is gone or not
  /// readable.
  ///
  /// Live UPDATES need `meeting_proposals` in the `supabase_realtime`
  /// publication and SELECT-able by both chat members (migration 0073). The
  /// degradation if either is missing is graceful rather than silent, unlike
  /// a bare `channel()` subscription: `.stream()` issues the initial select
  /// itself, so the card still renders the proposal's current status on open —
  /// only the live follow-up is lost.
  Stream<List<Map<String, dynamic>>> watchProposal(String proposalId) {
    return _client
        .from('meeting_proposals')
        .stream(primaryKey: ['id'])
        .eq('id', proposalId);
  }

  Future<void> submitReport(
    String reportedUserId,
    String reason,
    String details,
    List<String> imageUrls,
  ) {
    return _client.from('reports').insert({
      'reporter_id': currentUserId,
      'reported_user_id': reportedUserId,
      'reason': reason,
      'details': details,
      'image_urls': imageUrls,
    });
  }

  /// Uploads report evidence screenshots to the public `report-images`
  /// bucket, mirroring `EventsRemoteDataSource.uploadEventImage`.
  Future<String> uploadReportImage(File file) async {
    final extension = file.path.split('.').last.toLowerCase();
    final path =
        'report-${DateTime.now().microsecondsSinceEpoch}'
        '.${extension.isEmpty ? 'jpg' : extension}';

    await _client.storage
        .from('report-images')
        .upload(path, file, fileOptions: const FileOptions(upsert: true));
    return _client.storage.from('report-images').getPublicUrl(path);
  }
}
