import 'home_summary.dart';
import 'student_preview.dart';

/// Everything the home screen needs, fetched together by
/// `LoadHomeDashboard` so the screen has one loading/error state instead of
/// juggling several separate futures.
///
/// Event data (browsing, registering, My Events) no longer lives here — see
/// the `events` feature, carved out in Phase B once "a list on the home
/// dashboard" grew into a full subsystem (approval, visibility, QR
/// attendance). This entity keeps only what the dashboard itself renders.
class HomeDashboard {
  const HomeDashboard({
    required this.viewerId,
    required this.greetingName,
    required this.summary,
    required this.newStudents,
  });

  final String viewerId;
  final String greetingName;
  final HomeSummary summary;
  final List<StudentPreview> newStudents;
}
