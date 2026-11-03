import '../entities/campus_event.dart';
import '../repositories/events_repository.dart';

/// Fetches every event the viewer has registered for or attended — past or
/// future — for the "My Events" screen's All/Upcoming/Attended/Missed
/// filter. Unlike `LoadEventList`, this deliberately does not exclude
/// already-ended events (Attended/Missed only make sense for events that
/// have already happened).
class LoadMyEvents {
  const LoadMyEvents(this._repository);
  final EventsRepository _repository;

  Future<List<CampusEvent>> call() {
    return _repository.getMyEvents();
  }
}
