import 'dart:io';

import '../../domain/entities/chat.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/meeting_proposal.dart';
import '../../domain/entities/proposal_action_result.dart';
import '../../domain/entities/send_message_result.dart';
import '../../domain/entities/submit_report_result.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._remote);

  final ChatRemoteDataSource _remote;

  @override
  Future<List<Chat>> listMyChats() async {
    final rows = await _remote.listMyChats();
    return rows.map((row) {
      return Chat(
        id: row['chat_id'] as String,
        otherUserId: row['other_user_id'] as String,
        otherFullName: (row['other_full_name'] as String?) ?? '',
        otherAvatarUrl: row['other_avatar_url'] as String?,
        otherAvatarHue: (row['other_avatar_hue'] as int?) ?? 220,
        lastMessageBody: row['last_message_body'] as String?,
        lastMessageAt: row['last_message_at'] != null
            ? _parseUtcTimestamp(row['last_message_at'] as String)
            : null,
        lastMessageSenderId: row['last_message_sender_id'] as String?,
        unreadCount: (row['unread_count'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  @override
  Future<void> markChatRead(String chatId) => _remote.markChatRead(chatId);

  @override
  Future<String> getOrCreateChat(String otherUserId) =>
      _remote.getOrCreateChat(otherUserId);

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _remote.watchMessages(chatId).map((rows) {
      return rows.map((row) {
        final metadata = row['metadata'] as Map<String, dynamic>?;
        return ChatMessage(
          id: row['id'] as String,
          chatId: row['chat_id'] as String,
          senderId: row['sender_id'] as String,
          body: row['body'] as String,
          type: (row['message_type'] as String?) == 'meeting_proposal'
              ? ChatMessageType.meetingProposal
              : ChatMessageType.text,
          createdAt: _parseUtcTimestamp(row['created_at'] as String),
          proposalId: metadata?['proposal_id'] as String?,
        );
      }).toList();
    });
  }

  @override
  Future<SendMessageResult> sendMessage(String chatId, String body) async {
    final result = await _remote.sendMessage(chatId, body);
    return switch (result['status']) {
      'ok' => SendMessageResult.ok,
      'blocked' => SendMessageResult.blocked,
      'empty' => SendMessageResult.empty,
      'forbidden' => SendMessageResult.forbidden,
      _ => SendMessageResult.unknown,
    };
  }

  @override
  Future<void> blockUser(String userId) => _remote.blockUser(userId);

  @override
  Future<void> unblockUser(String userId) => _remote.unblockUser(userId);

  @override
  Future<bool> haveIBlocked(String otherUserId) =>
      _remote.haveIBlocked(otherUserId);

  @override
  Future<ProposeMeetingResult> proposeMeeting(
    String chatId, {
    required DateTime scheduledAt,
    required DateTime endsAt,
    String? location,
    String? notes,
  }) async {
    final result = await _remote.proposeMeeting(
      chatId,
      scheduledAt,
      endsAt,
      location,
      notes,
    );
    return switch (result['status']) {
      'ok' => ProposeMeetingResult.ok,
      'forbidden' => ProposeMeetingResult.forbidden,
      'not_found' => ProposeMeetingResult.notFound,
      'invalid_window' => ProposeMeetingResult.invalidWindow,
      'daily_pair_limit' => ProposeMeetingResult.dailyPairLimit,
      'daily_partner_limit' =>
        result['who'] == 'other'
            ? ProposeMeetingResult.dailyPartnerLimitOther
            : ProposeMeetingResult.dailyPartnerLimitSelf,
      _ => ProposeMeetingResult.unknown,
    };
  }

  @override
  Future<RespondProposalResult> respondToProposal(
    String proposalId, {
    required bool accept,
  }) async {
    final result = await _remote.respondToProposal(proposalId, accept);
    return switch (result['status']) {
      'ok' => RespondProposalResult.ok,
      'forbidden' => RespondProposalResult.forbidden,
      'not_found' => RespondProposalResult.notFound,
      'already_responded' => RespondProposalResult.alreadyResponded,
      'daily_pair_limit' => RespondProposalResult.dailyPairLimit,
      'daily_partner_limit' =>
        result['who'] == 'other'
            ? RespondProposalResult.dailyPartnerLimitOther
            : RespondProposalResult.dailyPartnerLimitSelf,
      _ => RespondProposalResult.unknown,
    };
  }

  @override
  Stream<MeetingProposal?> watchProposal(String proposalId) {
    return _remote.watchProposal(proposalId).map((rows) {
      if (rows.isEmpty) return null;
      return _proposalFromRow(rows.first);
    });
  }

  MeetingProposal _proposalFromRow(Map<String, dynamic> row) {
    return MeetingProposal(
      id: row['id'] as String,
      chatId: row['chat_id'] as String,
      proposedBy: row['proposed_by'] as String,
      proposedAt: _parseUtcTimestamp(row['proposed_at'] as String),
      scheduledAt: _parseUtcTimestamp(row['scheduled_at'] as String),
      endsAt: _parseUtcTimestamp(row['ends_at'] as String),
      location: row['location'] as String?,
      notes: row['notes'] as String?,
      status: switch (row['status']) {
        'accepted' => MeetingProposalStatus.accepted,
        'declined' => MeetingProposalStatus.declined,
        _ => MeetingProposalStatus.pending,
      },
    );
  }

  @override
  Future<SubmitReportResult> submitReport(
    String reportedUserId, {
    required String reason,
    required String details,
    List<String> imageUrls = const [],
  }) async {
    try {
      await _remote.submitReport(reportedUserId, reason, details, imageUrls);
      return SubmitReportResult.ok;
    } catch (_) {
      return SubmitReportResult.unknown;
    }
  }

  @override
  Future<String> uploadReportImage(File file) =>
      _remote.uploadReportImage(file);
}

/// `watchMessages` is fed by Supabase Realtime (`.stream()`), which passes
/// `timestamptz` values through from the WAL as raw Postgres text — unlike
/// PostgREST responses, that text isn't guaranteed to carry a `Z`/offset
/// suffix. `DateTime.parse` treats a suffix-less string as local time, which
/// silently corrupts the "arrives as UTC" assumption the rest of the chat
/// feature relies on (see `chat_thread_screen.dart`'s `_buildThreadItems`).
/// Normalize first so the result is always correctly UTC.
DateTime _parseUtcTimestamp(String raw) {
  final hasOffset = RegExp(r'(Z|[+-]\d\d(:?\d\d)?)$').hasMatch(raw);
  final iso = raw.replaceFirst(' ', 'T');
  return DateTime.parse(hasOffset ? iso : '${iso}Z');
}
