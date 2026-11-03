import 'package:c2c/features/notifications/domain/entities/app_notification.dart';
import 'package:c2c/features/notifications/domain/usecases/pending_event_reminders.dart';
import 'package:flutter_test/flutter_test.dart';

/// 10 October 2026, the day the fixtures below revolve around.
final _today = DateTime(2026, 10, 10);

AppNotification _reminder({
  required AppNotificationType type,
  String eventId = 'event-1',
  String eventDay = '2026-10-10',
  String startsAt = '2026-10-10T09:00:00Z',
  String endsAt = '2026-10-10T11:00:00Z',
  Map<String, dynamic>? extraData,
}) {
  return AppNotification(
    id: 'n-$eventId-${type.name}',
    type: type,
    data: {
      'event_id': eventId,
      'event_day': eventDay,
      'starts_at': startsAt,
      'ends_at': endsAt,
      'title': 'Career Fair',
      ...?extraData,
    },
    createdAt: DateTime.utc(2026, 10, 9, 6),
  );
}

List<EventReminder> _due(
  List<AppNotification> notifications, {
  DateTime? today,
  Set<String> alreadyShown = const {},
}) {
  return pendingEventReminders(
    notifications,
    today: today ?? _today,
    hasBeenShown: (r) =>
        alreadyShown.contains('${r.eventId}.${r.kind}.${r.eventDay}'),
  );
}

void main() {
  group('pendingEventReminders', () {
    test('a today-reminder for an event today is due', () {
      final due = _due([
        _reminder(type: AppNotificationType.eventReminderToday),
      ]);
      expect(due, hasLength(1));
      expect(due.single.isToday, isTrue);
      expect(due.single.kind, 'today');
      expect(due.single.eventId, 'event-1');
    });

    test('a tomorrow-reminder is due on the day BEFORE its event', () {
      final due = _due([
        _reminder(
          type: AppNotificationType.eventReminderTomorrow,
          eventDay: '2026-10-11',
          startsAt: '2026-10-11T09:00:00Z',
          endsAt: '2026-10-11T11:00:00Z',
        ),
      ]);
      expect(due, hasLength(1));
      expect(due.single.isToday, isFalse);
      expect(due.single.kind, 'tomorrow');
    });

    test('a tomorrow-reminder is NOT due on the event day itself', () {
      // Its day was yesterday; the today-reminder covers the event day.
      final due = _due([
        _reminder(type: AppNotificationType.eventReminderTomorrow),
      ]);
      expect(due, isEmpty);
    });

    test(
      "a reminder whose day has passed never pops again — the user didn't "
      'open the app that day',
      () {
        final due = _due([
          _reminder(
            type: AppNotificationType.eventReminderToday,
            eventDay: '2026-10-08',
            startsAt: '2026-10-08T09:00:00Z',
            endsAt: '2026-10-08T11:00:00Z',
          ),
        ]);
        expect(due, isEmpty);
      },
    );

    test('a reminder for a future day is not due yet', () {
      final due = _due([
        _reminder(
          type: AppNotificationType.eventReminderToday,
          eventDay: '2026-10-20',
          startsAt: '2026-10-20T09:00:00Z',
          endsAt: '2026-10-20T11:00:00Z',
        ),
      ]);
      expect(due, isEmpty);
    });

    test('an already-shown reminder is not due again', () {
      final due = _due(
        [_reminder(type: AppNotificationType.eventReminderToday)],
        alreadyShown: {'event-1.today.2026-10-10'},
      );
      expect(due, isEmpty);
    });

    test(
      'the same event on a NEW day is due again — a rescheduled event is '
      'remindable',
      () {
        final due = _due(
          [
            _reminder(
              type: AppNotificationType.eventReminderToday,
              eventDay: '2026-10-10',
            ),
          ],
          // Shown for the day it used to be on, not for today.
          alreadyShown: {'event-1.today.2026-10-02'},
        );
        expect(due, hasLength(1));
      },
    );

    test('non-reminder notifications are ignored', () {
      final due = _due([
        AppNotification(
          id: 'n-published',
          type: AppNotificationType.eventPublished,
          data: const {'event_id': 'event-1', 'title': 'Career Fair'},
          createdAt: DateTime.utc(2026, 10, 10),
        ),
      ]);
      expect(due, isEmpty);
    });

    test('a reminder missing payload fields is skipped, not thrown on', () {
      final due = _due([
        AppNotification(
          id: 'n-broken',
          type: AppNotificationType.eventReminderToday,
          // No event_day, no starts_at/ends_at.
          data: const {'event_id': 'event-1'},
          createdAt: DateTime.utc(2026, 10, 10),
        ),
      ]);
      expect(due, isEmpty);
    });

    test('several due reminders come back soonest-event-first', () {
      final due = _due([
        _reminder(
          type: AppNotificationType.eventReminderToday,
          eventId: 'late',
          startsAt: '2026-10-10T18:00:00Z',
          endsAt: '2026-10-10T20:00:00Z',
        ),
        _reminder(
          type: AppNotificationType.eventReminderToday,
          eventId: 'early',
          startsAt: '2026-10-10T08:00:00Z',
          endsAt: '2026-10-10T09:00:00Z',
        ),
      ]);
      expect(due.map((r) => r.eventId), ['early', 'late']);
    });
  });

  group('parseEventReminder', () {
    test('reads an offset-less timestamp as UTC, not as local time', () {
      // Postgres can return a timestamptz with no Z/offset suffix;
      // DateTime.parse would then read it as local and shift the instant.
      final reminder = parseEventReminder(
        _reminder(
          type: AppNotificationType.eventReminderToday,
          startsAt: '2026-10-10 09:00:00',
          endsAt: '2026-10-10 11:00:00',
        ),
      );
      expect(reminder, isNotNull);
      expect(reminder!.startsAt, DateTime.utc(2026, 10, 10, 9));
      expect(reminder.startsAt.isUtc, isTrue);
    });

    test('returns null for a notification that is not a reminder', () {
      expect(
        parseEventReminder(
          AppNotification(
            id: 'n',
            type: AppNotificationType.newMessage,
            data: const {},
            createdAt: DateTime.utc(2026, 10, 10),
          ),
        ),
        isNull,
      );
    });
  });
}
