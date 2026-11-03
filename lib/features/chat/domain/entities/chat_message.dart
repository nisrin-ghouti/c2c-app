enum ChatMessageType { text, meetingProposal }

/// One message in a chat thread.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.body,
    required this.type,
    required this.createdAt,
    this.proposalId,
  });

  final String id;
  final String chatId;
  final String senderId;
  final String body;
  final ChatMessageType type;
  final DateTime createdAt;

  /// Only set when [type] is `meetingProposal` — the id of the
  /// `MeetingProposal` this message renders as an inline card for.
  final String? proposalId;
}
