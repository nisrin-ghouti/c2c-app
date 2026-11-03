import 'event_kind.dart';
import 'event_session_draft.dart';
import 'event_visibility.dart';
import 'event_visibility_target.dart';

/// The editable fields of an event/program, as submitted from
/// `event_create_edit_screen` to `create_event_or_program`/
/// `update_event_or_program`. Kept separate from `CampusEvent` since a draft
/// has no id/createdBy/approvalStatus yet — those are server-assigned.
class EventDraft {
  const EventDraft({
    required this.title,
    this.description,
    this.category,
    this.location,
    required this.startsAt,
    required this.endsAt,
    required this.points,
    this.imageUrl,
    this.organizerName,
    this.organizerDescription,
    this.externalLink,
    required this.visibility,
    this.capacity,
    this.visibilityTargets = const [],
    this.eventKind = EventKind.single,
    this.sessions = const [],
  });

  final String title;
  final String? description;
  final String? category;
  final String? location;
  final DateTime startsAt;
  final DateTime endsAt;
  final int points;
  final String? imageUrl;
  final String? organizerName;
  final String? organizerDescription;
  final String? externalLink;
  final EventVisibility visibility;
  final int? capacity;
  final List<EventVisibilityTarget> visibilityTargets;
  final EventKind eventKind;

  /// Only meaningful when [eventKind] is `program` — one row per session.
  final List<EventSessionDraft> sessions;

  Map<String, dynamic> toEventJson() => {
    'title': title,
    'description': description,
    'category': category,
    'location': location,
    // .toUtc() first: startsAt/endsAt come from the date/time picker as
    // local wall-clock DateTimes (isUtc: false). Serializing those
    // directly omits a timezone offset, so Postgres would store the
    // picked local time as if it were already UTC — shifting the real
    // instant by the picker's UTC offset. Converting to UTC before
    // encoding keeps the actual moment in time correct regardless of
    // which timezone the event was created in.
    'starts_at': startsAt.toUtc().toIso8601String(),
    'ends_at': endsAt.toUtc().toIso8601String(),
    'points': points,
    'image_url': imageUrl,
    'organizer_name': organizerName,
    'organizer_description': organizerDescription,
    'external_link': externalLink,
    'visibility': visibility.dbValue,
    'capacity': capacity,
    'visibility_targets': visibilityTargets.map((t) => t.toJson()).toList(),
    'event_kind': eventKind.dbValue,
  };

  /// `null` means "don't touch existing sessions" (single events, or a
  /// program edit that isn't changing its session list) — the RPC only
  /// replaces sessions when this is non-null.
  List<Map<String, dynamic>>? toSessionsJson() {
    if (eventKind != EventKind.program) return null;
    return sessions.map((s) => s.toJson()).toList();
  }
}
