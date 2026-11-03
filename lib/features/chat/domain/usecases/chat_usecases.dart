import 'dart:io';

import '../entities/chat.dart';
import '../entities/meeting_proposal.dart';
import '../entities/proposal_action_result.dart';
import '../entities/send_message_result.dart';
import '../entities/submit_report_result.dart';
import '../repositories/chat_repository.dart';

class ListMyChats {
  const ListMyChats(this._repository);
  final ChatRepository _repository;

  Future<List<Chat>> call() => _repository.listMyChats();
}

class GetOrCreateChat {
  const GetOrCreateChat(this._repository);
  final ChatRepository _repository;

  Future<String> call(String otherUserId) =>
      _repository.getOrCreateChat(otherUserId);
}

class MarkChatRead {
  const MarkChatRead(this._repository);
  final ChatRepository _repository;

  Future<void> call(String chatId) => _repository.markChatRead(chatId);
}

class SendMessage {
  const SendMessage(this._repository);
  final ChatRepository _repository;

  Future<SendMessageResult> call(String chatId, String body) =>
      _repository.sendMessage(chatId, body);
}

class BlockUser {
  const BlockUser(this._repository);
  final ChatRepository _repository;

  Future<void> call(String userId) => _repository.blockUser(userId);
}

class UnblockUser {
  const UnblockUser(this._repository);
  final ChatRepository _repository;

  Future<void> call(String userId) => _repository.unblockUser(userId);
}

class ProposeMeeting {
  const ProposeMeeting(this._repository);
  final ChatRepository _repository;

  Future<ProposeMeetingResult> call(
    String chatId, {
    required DateTime scheduledAt,
    required DateTime endsAt,
    String? location,
    String? notes,
  }) => _repository.proposeMeeting(
    chatId,
    scheduledAt: scheduledAt,
    endsAt: endsAt,
    location: location,
    notes: notes,
  );
}

class RespondToProposal {
  const RespondToProposal(this._repository);
  final ChatRepository _repository;

  Future<RespondProposalResult> call(
    String proposalId, {
    required bool accept,
  }) => _repository.respondToProposal(proposalId, accept: accept);
}

class WatchProposal {
  const WatchProposal(this._repository);
  final ChatRepository _repository;

  Stream<MeetingProposal?> call(String proposalId) =>
      _repository.watchProposal(proposalId);
}

class SubmitReport {
  const SubmitReport(this._repository);
  final ChatRepository _repository;

  Future<SubmitReportResult> call(
    String reportedUserId, {
    required String reason,
    required String details,
    List<String> imageUrls = const [],
  }) => _repository.submitReport(
    reportedUserId,
    reason: reason,
    details: details,
    imageUrls: imageUrls,
  );
}

class UploadReportImage {
  const UploadReportImage(this._repository);
  final ChatRepository _repository;

  Future<String> call(File file) => _repository.uploadReportImage(file);
}
