import '../entities/campus_event.dart';
import '../entities/program_session_window.dart';
import '../entities/event_kind.dart';
import '../repositories/events_repository.dart';
import 'stitch_registration_status.dart';

/// Fetches the browsable upcoming-events list and stitches each event's
/// registration status onto it — the "business rule" that turns raw id
/// sets into the tri-state `EventRegistrationStatus` each card renders.
/// Each dependency is fetched defensively (falls back to empty on error)
/// rather than failing the whole screen, same convention as
/// `LoadHomeDashboard`.
class LoadEventList {
  const LoadEventList(this._repository);
  final EventsRepository _repository;

  Future<T> _orDefault<T>(Future<T> future, T fallback) {
    return future.catchError((_) => fallback);
  }

  Future<List<CampusEvent>> call() async {
    final results = await Future.wait([
      _repository.getUpcomingEvents(),
      _orDefault(_repository.getMyRegisteredEventIds(), const <String>{}),
      _orDefault(_repository.getMyAttendedEventIds(), const <String>{}),
      _orDefault(
        _repository.getMyAttendedSessionCountsByEvent(),
        const <String, int>{},
      ),
    ]);
    final events = results[0] as List<CampusEvent>;

    // Only programs need the session-count round trip, and only once the
    // list is in hand — so this one can't join the batch above.
    final programIds = events
        .where((event) => event.eventKind == EventKind.program)
        .map((event) => event.id)
        .toList();
    final sessionCounts = await _orDefault(
      _repository.getSessionCountsByEvent(programIds),
      const <String, ProgramSessionWindow>{},
    );

    return stitchRegistrationStatus(
      events,
      registeredIds: results[1] as Set<String>,
      attendedIds: results[2] as Set<String>,
      attendedSessionCounts: results[3] as Map<String, int>,
      sessionCounts: sessionCounts,
    );
  }
}
