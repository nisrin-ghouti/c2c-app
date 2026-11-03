/// One 1:1 conversation, as shown on the chat list — enriched with the
/// other participant's display info and a preview of the last message so
/// the list screen doesn't need a second round trip per row.
class Chat {
  const Chat({
    required this.id,
    required this.otherUserId,
    required this.otherFullName,
    this.otherAvatarUrl,
    required this.otherAvatarHue,
    this.lastMessageBody,
    this.lastMessageAt,
    this.lastMessageSenderId,
    this.unreadCount = 0,
  });

  final String id;
  final String otherUserId;
  final String otherFullName;
  final String? otherAvatarUrl;
  final int otherAvatarHue;
  final String? lastMessageBody;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final int unreadCount;
}
