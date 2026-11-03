enum AppNotificationType {
  pointsEarned,
  newMessage,
  meetingProposal,

  /// Admin-only: a host submitted an event that needs approval.
  eventPendingApproval,

  /// Campus-wide: a new event became visible to students.
  eventPublished,

  /// Campus-wide: a new benefit became redeemable.
  benefitPublished,

  /// Admin-only: a student filed a report.
  reportSubmitted,

  /// Host-only: their event was approved or rejected.
  eventDecision,

  /// Admin-only: a group meeting is waiting for approval.
  groupMeetingPending,

  /// The student's digital card was redeemed by a partner.
  benefitRedeemed,

  /// Campus-wide: a new survey became available.
  surveyPublished,

  /// Registrant-only: an event they signed up for happens tomorrow. Written
  /// by `dispatch_event_reminders()` (migration 0076).
  eventReminderTomorrow,

  /// Registrant-only: an event they signed up for happens today.
  eventReminderToday,

  unknown,
}

/// One row of `notifications` — a generic `type` + `data` jsonb shape;
/// [data]'s keys depend on [type] (see `reason_label.dart`-style mapping in
/// the presentation widget that renders these).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final AppNotificationType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isUnread => readAt == null;

  /// Whether this is one of the two event reminders — the types that also
  /// drive the once-a-day centre-screen popup.
  bool get isEventReminder =>
      type == AppNotificationType.eventReminderTomorrow ||
      type == AppNotificationType.eventReminderToday;
}
