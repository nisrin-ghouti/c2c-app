import 'dart:io';

import '../entities/chat.dart';
import '../entities/chat_message.dart';
import '../entities/meeting_proposal.dart';
import '../entities/proposal_action_result.dart';
import '../entities/send_message_result.dart';
import '../entities/submit_report_result.dart';

/// The seam between the chat feature's domain/presentation layers and
/// Supabase. See `ChatRemoteDataSource` for the actual table/RPC/realtime
/// calls.
abstract interface class ChatRepository {
  /// Every conversation the viewer is part of, most-recent-message first.
  Future<List<Chat>> listMyChats();

  /// Returns the existing 1:1 chat with [otherUserId], creating it if this
  /// is the first time these two have messaged.
  Future<String> getOrCreateChat(String otherUserId);

  /// Marks every message in [chatId] as read by the viewer, zeroing its
  /// unread count on the chat list.
  Future<void> markChatRead(String chatId);

  /// Realtime feed of a chat's full message list — re-emits the whole set
  /// on every change (same `.stream()` convention already used by
  /// `MatchesRepository.watchSessionClaimed`).
  Stream<List<ChatMessage>> watchMessages(String chatId);

  /// Atomic server-side send — rejects if either participant has blocked
  /// the other.
  Future<SendMessageResult> sendMessage(String chatId, String body);

  Future<void> blockUser(String userId);

  Future<void> unblockUser(String userId);

  /// Whether the viewer has blocked [otherUserId] (not the reverse).
  Future<bool> haveIBlocked(String otherUserId);

  Future<ProposeMeetingResult> proposeMeeting(
    String chatId, {
    required DateTime scheduledAt,
    required DateTime endsAt,
    String? location,
    String? notes,
  });

  Future<RespondProposalResult> respondToProposal(
    String proposalId, {
    required bool accept,
  });

  /// Live view of one meeting proposal — emits the row's current state, then
  /// again whenever it changes, so a status set by the other participant
  /// reaches this one's chat card without a refresh. Emits null once the row is
  /// gone or unreadable.
  ///
  /// Replaced a one-shot read: the first emission already carries the current
  /// status, so nothing needed both.
  Stream<MeetingProposal?> watchProposal(String proposalId);

  /// Submits a report against [reportedUserId] for admin review — reachable
  /// from a chat thread or a match's profile screen.
  Future<SubmitReportResult> submitReport(
    String reportedUserId, {
    required String reason,
    required String details,
    List<String> imageUrls,
  });

  /// Uploads one report evidence screenshot, returning its public URL.
  Future<String> uploadReportImage(File file);
}
