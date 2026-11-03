/// A program's real schedule, derived from its `event_sessions` rows.
///
/// A program's own `events.starts_at`/`ends_at` are not reliably the span of
/// its meetings — they are whatever was typed into the event form, and in
/// practice they drift from (or contradict) the sessions underneath. One live
/// program carries `starts_at` 22 Dec with `ends_at` 11 Nov while its five
/// sessions run 11 Nov → 9 Dec, so date rules applied to the event row put it
/// in the wrong month and, with the end before the start, in no window at all.
///
/// The sessions are the schedule. This carries their envelope so a program can
/// be placed on the calendar by when it actually meets.
class ProgramSessionWindow {
  const ProgramSessionWindow({
    required this.sessionCount,
    required this.firstStartsAt,
    required this.lastEndsAt,
  });

  final int sessionCount;

  /// Earliest `starts_at` across the program's sessions.
  final DateTime firstStartsAt;

  /// Latest `ends_at` across them — not the last session's start, since
  /// sessions may be listed in any order and the longest one need not be last.
  final DateTime lastEndsAt;
}
