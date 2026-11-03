/// Centralized route path constants — avoids typo'd string literals
/// scattered across `context.go(...)` calls.
abstract final class AppRoutes {
  static const language = '/language';
  static const auth = '/auth';
  static const verifyOtp = '/auth/verify';
  static const forgotPassword = '/auth/forgot-password';

  /// Deliberately *not* nested under [auth]: a user can hold a valid
  /// (password-recovery) session while on this screen, and the router's
  /// "signed in + on an auth route -> bounce home" rule must not apply here.
  static const resetPassword = '/reset-password';

  static const completeProfile = '/complete-profile';
  static const policy = '/policy';
  static const onboardingTutorial = '/onboarding-tutorial';

  /// Dead-end screen for Admin/Host-only accounts — this Flutter app is
  /// student-facing only, so those accounts are hard-gated here instead of
  /// ever reaching the main shell. See `isStudentEligibleProvider`.
  static const studentAppRestricted = '/student-app-restricted';

  static const events = '/events';

  /// The Events list restricted to the next 30 days — where Home's "Events in
  /// the Next Month" section's "See All" goes, so it opens the same set the
  /// section previews. See `EventListScreen.onlyNextThirtyDays`.
  static const eventsNextMonth = '/events/next-month';

  /// One event by id, for a shared link (`AppConfig.eventShareUrl`). Not used
  /// for in-app navigation, which pushes `EventDetailScreen` with the event it
  /// already holds.
  static const eventByIdPattern = '/events/by-id/:eventId';
  static String eventById(String id) => '/events/by-id/$id';

  static const myEvents = '/my-events';

  static const chats = '/chats';
  static const notifications = '/notifications';

  static const groupMeetings = '/group-meetings';
  static const groupMeetingJoinBase = '/group-meetings/join';

  static const surveys = '/surveys';

  // Bottom-nav shell branches.
  static const home = '/';
  static const matches = '/matches';
  static const connect = '/connect';
  static const benefits = '/benefits';
  static const profile = '/profile';
}
