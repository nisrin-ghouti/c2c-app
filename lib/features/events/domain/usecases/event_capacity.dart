import '../entities/campus_event.dart';

/// How full an event is — its `capacity` paired with the live registration
/// count that only `get_event_registration_counts` can supply (migration
/// 0065).
///
/// `register_for_event` enforces the same comparison server-side and is still
/// the authority; this exists so the UI can say "full" up front instead of
/// letting the student tap Register and reading the refusal back as an error.
class EventCapacity {
  const EventCapacity({required this.registered, required this.capacity});

  /// An event with no capacity set — unlimited, so never full.
  const EventCapacity.unlimited() : registered = 0, capacity = null;

  /// People currently holding a `registered` row for the event.
  final int registered;

  /// The cap the organizer set, or null for "no limit".
  final int? capacity;

  /// True once the places have run out. Recomputed from whatever the latest
  /// count and capacity are, so raising the cap or a cancellation frees the
  /// registration UI again without any extra bookkeeping.
  bool get isFull {
    final cap = capacity;
    return cap != null && cap > 0 && registered >= cap;
  }

  /// Places left, or null when the event is uncapped.
  int? get remaining {
    final cap = capacity;
    if (cap == null) return null;
    final left = cap - registered;
    return left < 0 ? 0 : left;
  }
}

/// [EventCapacity] for [event] given a map of event_id → registration count.
/// A missing entry means nobody has registered yet, not unknown — the RPC
/// omits events with no registrations.
EventCapacity capacityOf(CampusEvent event, Map<String, int> counts) {
  return EventCapacity(
    registered: counts[event.id] ?? 0,
    capacity: event.capacity,
  );
}

/// Whether registration is unavailable for [event] right now, for either
/// reason: the places have run out, or an admin closed registration by hand
/// (`events.registration_closed`, migration 0070).
///
/// One helper so every surface asks the identical question. The event card's
/// external Register button used to consult capacity alone, so a manually
/// closed event still offered a live-looking button there while the detail
/// screen correctly refused — and tapping it produced a server refusal
/// rendered as an error.
///
/// Both states present the same way ("האירוע מלא", grey and disabled), which
/// is deliberate: from the student's side "no places" and "closed" are the
/// same fact, and the detail screen carries the longer explanation.
bool registrationBlocked(CampusEvent event, Map<String, int> counts) {
  return event.registrationClosed || capacityOf(event, counts).isFull;
}
