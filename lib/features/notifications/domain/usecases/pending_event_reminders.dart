import '../entities/app_notification.dart';

/// One event reminder, parsed out of its notification row and ready to render
/// as the centre-screen popup.
///
/// Everything it needs travels in `notifications.data` (written by
/// `dispatch_event_reminders()`, migration 0076), so showing the popup costs
/// no extra fetch — including the per-locale title/location copies, which the
/// widget resolves with `localizedNotificationField`.
class EventReminder {
  const EventReminder({
    required this.notification,
    required this.eventId,
    required this.isToday,
    required this.eventDay,
    required this.startsAt,
    required this.endsAt,
  });

  final AppNotification notification;
  final String eventId;

  /// True for the day-of reminder, false for the day-before one.
  final bool isToday;

  /// The event's campus-local start date, as the `YYYY-MM-DD` string the
  /// server wrote. Used verbatim as part of the "already shown" key so the
  /// client and `event_reminder_sends` agree on what a day is.
  final String eventDay;

  final DateTime startsAt;
  final DateTime endsAt;

  /// `'today'` / `'tomorrow'` — the `kind` half of the "already shown" key,
  /// matching `event_reminder_sends.kind`.
  String get kind => isToday ? 'today' : 'tomorrow';

  Map<String, dynamic> get data => notification.data;
}

/// The reminders whose popup is due right now, most imminent first.
///
/// A reminder qualifies when all three hold:
///
///   * it is one of the two reminder types and its payload parses;
///   * **its own day is [today]** — that is the event's day for a `today`
///     reminder and the day before for a `tomorrow` one. This is the rule that
///     implements "if the user doesn't open the app on the relevant day, don't
///     show that day's popup later": once the date rolls over, the reminder
///     stops qualifying permanently and lives on only in the notification
///     centre;
///   * [hasBeenShown] says this device hasn't already popped it (keyed by
///     event + kind + day, persisted in `AppPreferences`), so dismissing it
///     is final even across a restart.
///
/// [today] is the device's local date. Campus time is what the server used, and
/// a student on campus has their device on campus time; a device deliberately
/// set to another zone can be a day out, which is the same assumption every
/// `toLocal()` in this app already makes.
///
/// Pure, so the whole rule is testable without a provider, a clock, or
/// SharedPreferences.
List<EventReminder> pendingEventReminders(
  List<AppNotification> notifications, {
  required DateTime today,
  required bool Function(EventReminder reminder) hasBeenShown,
}) {
  final due = <EventReminder>[];
  for (final notification in notifications) {
    final reminder = parseEventReminder(notification);
    if (reminder == null) continue;

    final eventDay = DateTime.tryParse(reminder.eventDay);
    if (eventDay == null) continue;
    final reminderDay = reminder.isToday
        ? eventDay
        : DateTime(eventDay.year, eventDay.month, eventDay.day - 1);
    if (!_isSameDate(reminderDay, today)) continue;

    if (hasBeenShown(reminder)) continue;
    due.add(reminder);
  }

  // Soonest event first: if a student has two reminders waiting, the one
  // happening next is the one they need.
  due.sort((a, b) => a.startsAt.compareTo(b.startsAt));
  return due;
}

/// [notification] as an [EventReminder], or null when it isn't a reminder or
/// its payload is missing something the popup can't do without.
EventReminder? parseEventReminder(AppNotification notification) {
  if (!notification.isEventReminder) return null;

  final eventId = notification.data['event_id'] as String?;
  final eventDay = notification.data['event_day'] as String?;
  final startsAtRaw = notification.data['starts_at'] as String?;
  final endsAtRaw = notification.data['ends_at'] as String?;
  if (eventId == null || eventId.isEmpty) return null;
  if (eventDay == null || eventDay.isEmpty) return null;
  if (startsAtRaw == null || endsAtRaw == null) return null;

  final startsAt = _parseUtcTimestamp(startsAtRaw);
  final endsAt = _parseUtcTimestamp(endsAtRaw);
  if (startsAt == null || endsAt == null) return null;

  return EventReminder(
    notification: notification,
    eventId: eventId,
    isToday: notification.type == AppNotificationType.eventReminderToday,
    eventDay: eventDay,
    startsAt: startsAt,
    endsAt: endsAt,
  );
}

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Parses a Postgres `timestamptz` that may arrive without a `Z`/offset
/// suffix. `DateTime.parse` reads a suffix-less string as local time, which
/// would shift the instant. Same helper as `chat_repository_impl.dart` and
/// `scheduled_meeting_providers.dart`.
DateTime? _parseUtcTimestamp(String raw) {
  final hasOffset = RegExp(r'(Z|[+-]\d\d(:?\d\d)?)$').hasMatch(raw);
  final iso = raw.replaceFirst(' ', 'T');
  return DateTime.tryParse(hasOffset ? iso : '${iso}Z');
}
