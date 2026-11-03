/// One session row as submitted from the create/edit form's session
/// sub-form — see `EventDraft.sessions`.
class EventSessionDraft {
  const EventSessionDraft({
    required this.title,
    required this.startsAt,
    required this.endsAt,
    this.location,
  });

  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? location;

  Map<String, dynamic> toJson() => {
    'title': title,
    // See `EventDraft.toEventJson`'s comment — same UTC-before-encoding
    // fix, otherwise a session's local picked time gets stored as if it
    // were already UTC.
    'starts_at': startsAt.toUtc().toIso8601String(),
    'ends_at': endsAt.toUtc().toIso8601String(),
    'location': location,
  };
}
