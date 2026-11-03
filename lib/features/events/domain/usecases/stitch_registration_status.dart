import '../entities/campus_event.dart';
import '../entities/program_session_window.dart';
import '../entities/event_kind.dart';
import '../entities/session_attendance_progress.dart';

/// Attaches each event's [EventRegistrationStatus] based on the viewer's
/// registered/attended id sets — the one bit of business logic shared by
/// both `LoadEventList` and `LoadMyEvents` (otherwise duplicated verbatim).
///
/// [attendedSessionCounts] and [sessionCounts] cover Programs, whose
/// attendance is recorded per session: a program only counts as attended once
/// every session has been scanned, and until then it carries a
/// [SessionAttendanceProgress] so screens can say how far along it is. Pass
/// them empty and programs fall back to the plain event-level tri-state.
List<CampusEvent> stitchRegistrationStatus(
  List<CampusEvent> events, {
  required Set<String> registeredIds,
  required Set<String> attendedIds,
  Map<String, int> attendedSessionCounts = const {},
  Map<String, ProgramSessionWindow> sessionCounts = const {},
}) {
  return events
      .map(
        (event) => stitchEventRegistrationStatus(
          event,
          registeredIds: registeredIds,
          attendedIds: attendedIds,
          attendedSessionCounts: attendedSessionCounts,
          sessionCounts: sessionCounts,
        ),
      )
      .toList();
}

/// [stitchRegistrationStatus] for a single event.
CampusEvent stitchEventRegistrationStatus(
  CampusEvent event, {
  required Set<String> registeredIds,
  required Set<String> attendedIds,
  Map<String, int> attendedSessionCounts = const {},
  Map<String, ProgramSessionWindow> sessionCounts = const {},
}) {
  final registered = registeredIds.contains(event.id);
  final attendedWholeEvent = attendedIds.contains(event.id);
  final sessionWindow = sessionCounts[event.id];
  final totalSessions = sessionWindow?.sessionCount;

  if (event.eventKind == EventKind.program && totalSessions != null) {
    final progress = SessionAttendanceProgress(
      attended: attendedSessionCounts[event.id] ?? 0,
      total: totalSessions,
    );
    // Scanning one session must not close the whole program out — that used
    // to hide the sessions list behind an "attended" banner, leaving the
    // student no way to check in to the sessions still ahead of them.
    final status = attendedWholeEvent || progress.isComplete
        ? EventRegistrationStatus.attended
        : registered || progress.hasAny
        ? EventRegistrationStatus.registered
        : EventRegistrationStatus.notRegistered;
    return event.copyWith(
      registrationStatus: status,
      sessionAttendance: progress,
      // The real schedule, so date rules stop trusting the event row's own
      // start/end for a program. See `CampusEvent.effectiveStartsAt`.
      sessionWindow: sessionWindow,
    );
  }

  final status = attendedWholeEvent
      ? EventRegistrationStatus.attended
      : registered
      ? EventRegistrationStatus.registered
      : EventRegistrationStatus.notRegistered;
  return event.copyWith(registrationStatus: status);
}
