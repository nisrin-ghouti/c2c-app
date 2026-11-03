import '../../../events/domain/repositories/events_repository.dart';
import '../entities/home_dashboard.dart';
import '../entities/home_summary.dart';
import '../entities/student_preview.dart';
import '../repositories/home_repository.dart';

/// Fetches everything the home screen needs in parallel — one loading/error
/// state instead of juggling several separate futures.
///
/// Each field is fetched defensively (falls back to an empty/zero value on
/// error) rather than failing the whole dashboard: a Supabase project that's
/// still being set up (e.g. missing an RPC or table) shouldn't turn "no
/// points system yet" into "the whole home screen is broken".
class LoadHomeDashboard {
  const LoadHomeDashboard(this._repository, this._eventsRepository);
  final HomeRepository _repository;
  final EventsRepository _eventsRepository;

  Future<T> _orDefault<T>(Future<T> future, T fallback) {
    return future.catchError((_) => fallback);
  }

  Future<HomeDashboard> call(String viewerId) async {
    final results = await Future.wait([
      _orDefault(_repository.getMyDisplayName(), ''),
      _orDefault(_repository.getMyPoints(), 0),
      _orDefault(_repository.getUnreadNotificationCount(), 0),
      _orDefault(_eventsRepository.getUpcomingEventCount(), 0),
      _orDefault(_repository.getNewStudents(), const <StudentPreview>[]),
    ]);

    final greetingName = results[0] as String;
    final points = results[1] as int;
    final unread = results[2] as int;
    final upcomingEventsCount = results[3] as int;
    final newStudents = results[4] as List<StudentPreview>;

    return HomeDashboard(
      viewerId: viewerId,
      greetingName: greetingName,
      summary: HomeSummary(
        points: points,
        unreadNotifications: unread,
        upcomingEventsCount: upcomingEventsCount,
      ),
      newStudents: newStudents,
    );
  }
}
