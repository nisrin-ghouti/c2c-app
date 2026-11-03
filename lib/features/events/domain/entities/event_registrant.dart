/// One row of `admin_list_event_registrants` — shown to hosts/admins.
class EventRegistrant {
  const EventRegistrant({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.registeredAt,
    this.attendedAt,
  });

  final String userId;
  final String fullName;
  final String? email;
  final DateTime registeredAt;
  final DateTime? attendedAt;

  bool get attended => attendedAt != null;
}
