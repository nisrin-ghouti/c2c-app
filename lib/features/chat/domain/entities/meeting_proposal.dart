enum MeetingProposalStatus { pending, accepted, declined }

/// An in-chat "let's meet" proposal — the `+` button next to the message
/// input creates one of these, rendered as an inline card in the thread.
class MeetingProposal {
  const MeetingProposal({
    required this.id,
    required this.chatId,
    required this.proposedBy,
    required this.proposedAt,
    required this.scheduledAt,
    required this.endsAt,
    this.location,
    this.notes,
    required this.status,
  });

  final String id;
  final String chatId;
  final String proposedBy;
  final DateTime proposedAt;
  final DateTime scheduledAt;
  final DateTime endsAt;
  final String? location;
  final String? notes;
  final MeetingProposalStatus status;
}
