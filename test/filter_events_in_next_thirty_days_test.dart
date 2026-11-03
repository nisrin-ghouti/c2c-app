import 'package:c2c/features/events/domain/entities/campus_event.dart';
import 'package:c2c/features/events/domain/entities/event_kind.dart';
import 'package:c2c/features/events/domain/usecases/filter_events_in_next_thirty_days.dart';
import 'package:c2c/features/events/domain/entities/program_session_window.dart';
import 'package:flutter_test/flutter_test.dart';

CampusEvent _event({
  required String id,
  required DateTime startsAt,
  DateTime? endsAt,
}) {
  return CampusEvent(
    id: id,
    title: 'Event $id',
    category: null,
    location: null,
    startsAt: startsAt,
    endsAt: endsAt ?? startsAt.add(const Duration(hours: 2)),
    points: 10,
    createdBy: 'host',
    eventKind: EventKind.single,
  );
}

void main() {
  group('thirtyDaysAfter', () {
    test('lands 30 days on, keeping the clock time', () {
      expect(
        thirtyDaysAfter(DateTime(2026, 10, 3, 9, 30)),
        DateTime(2026, 11, 2, 9, 30),
      );
    });

    test('crosses a year boundary', () {
      expect(thirtyDaysAfter(DateTime(2026, 12, 20)), DateTime(2027, 1, 19));
    });

    test('is always 30 days regardless of month length', () {
      // February is short, but the window does not shrink with it.
      expect(thirtyDaysAfter(DateTime(2026, 2, 1)), DateTime(2026, 3, 3));
      expect(thirtyDaysAfter(DateTime(2026, 1, 31)), DateTime(2026, 3, 2));
    });
  });

  group('filterEventsInNextThirtyDays', () {
    final now = DateTime(2026, 10, 3, 9);

    test('keeps an event inside the window', () {
      final events = [_event(id: 'e1', startsAt: DateTime(2026, 10, 25, 18))];

      expect(filterEventsInNextThirtyDays(events, now: now).map((e) => e.id), [
        'e1',
      ]);
    });

    test('keeps an event in the next calendar month but inside 30 days', () {
      // The point of the rolling window: 2 November is only 30 days out, so it
      // belongs here even though it is not "this month".
      final events = [_event(id: 'nov', startsAt: DateTime(2026, 11, 2, 8))];

      expect(filterEventsInNextThirtyDays(events, now: now).map((e) => e.id), [
        'nov',
      ]);
    });

    test('includes an event exactly on the closing edge', () {
      final events = [_event(id: 'edge', startsAt: DateTime(2026, 11, 2, 9))];

      expect(filterEventsInNextThirtyDays(events, now: now).map((e) => e.id), [
        'edge',
      ]);
    });

    test('drops an event past the 30-day edge', () {
      final events = [_event(id: 'far', startsAt: DateTime(2026, 11, 2, 10))];

      expect(filterEventsInNextThirtyDays(events, now: now), isEmpty);
    });

    test('the window does not thin out at the end of a month', () {
      // On the 31st, a "this month only" rule would show almost nothing; this
      // one still reaches a full 30 days ahead.
      final lastDay = DateTime(2026, 10, 31, 9);
      final events = [_event(id: 'nov20', startsAt: DateTime(2026, 11, 20))];

      expect(
        filterEventsInNextThirtyDays(events, now: lastDay).map((e) => e.id),
        ['nov20'],
      );
    });

    test('keeps an event already under way', () {
      final events = [
        _event(
          id: 'running',
          startsAt: DateTime(2026, 10, 3, 8),
          endsAt: DateTime(2026, 10, 3, 12),
        ),
      ];

      expect(filterEventsInNextThirtyDays(events, now: now).map((e) => e.id), [
        'running',
      ]);
    });

    test('drops an event that has already finished', () {
      final events = [
        _event(
          id: 'over',
          startsAt: DateTime(2026, 10, 2, 8),
          endsAt: DateTime(2026, 10, 2, 12),
        ),
      ];

      expect(filterEventsInNextThirtyDays(events, now: now), isEmpty);
    });

    test('preserves the order it was given', () {
      final events = [
        _event(id: 'b', startsAt: DateTime(2026, 10, 20)),
        _event(id: 'a', startsAt: DateTime(2026, 10, 12)),
        _event(id: 'far', startsAt: DateTime(2026, 12, 1)),
        _event(id: 'c', startsAt: DateTime(2026, 11, 1)),
      ];

      expect(filterEventsInNextThirtyDays(events, now: now).map((e) => e.id), [
        'b',
        'a',
        'c',
      ]);
    });
  });

  group('programs are judged by their sessions, not the event row', () {
    // The shape one live program actually has: event row start seven weeks
    // AFTER its end, with the real meetings running in between. Before
    // `effectiveStartsAt` this fell outside every window and vanished from
    // the section.
    CampusEvent programWithSessions({
      required DateTime rowStart,
      required DateTime rowEnd,
      required DateTime firstSession,
      required DateTime lastSessionEnd,
    }) {
      return CampusEvent(
        id: 'program',
        title: 'starTAU',
        category: 'General',
        location: 'Campus',
        startsAt: rowStart,
        endsAt: rowEnd,
        points: 0,
        createdBy: 'admin',
        eventKind: EventKind.program,
        sessionWindow: ProgramSessionWindow(
          sessionCount: 5,
          firstStartsAt: firstSession,
          lastEndsAt: lastSessionEnd,
        ),
      );
    }

    test('included when its first session is inside the window', () {
      final now = DateTime(2026, 10, 13);
      final program = programWithSessions(
        rowStart: DateTime(2026, 12, 22),
        rowEnd: DateTime(2026, 11, 11),
        firstSession: DateTime(2026, 11, 11, 14, 15),
        lastSessionEnd: DateTime(2026, 12, 9, 16),
      );
      expect(
        filterEventsInNextThirtyDays([program], now: now).map((e) => e.id),
        ['program'],
      );
    });

    test('excluded when its first session is beyond the window', () {
      final now = DateTime(2026, 10, 13);
      final program = programWithSessions(
        rowStart: DateTime(2026, 10, 20),
        rowEnd: DateTime(2026, 10, 25),
        firstSession: DateTime(2027, 2, 1),
        lastSessionEnd: DateTime(2027, 3, 1),
      );
      expect(filterEventsInNextThirtyDays([program], now: now), isEmpty);
    });

    test('a program whose sessions all finished is dropped', () {
      final now = DateTime(2026, 10, 13);
      final program = programWithSessions(
        rowStart: DateTime(2026, 11, 1),
        rowEnd: DateTime(2026, 11, 30),
        firstSession: DateTime(2026, 9, 1),
        lastSessionEnd: DateTime(2026, 9, 30),
      );
      expect(filterEventsInNextThirtyDays([program], now: now), isEmpty);
    });

    test('falls back to the event row when it has no sessions', () {
      final now = DateTime(2026, 10, 13);
      final program = CampusEvent(
        id: 'no-sessions',
        title: 'empty program',
        category: 'General',
        location: 'Campus',
        startsAt: now.add(const Duration(days: 3)),
        endsAt: now.add(const Duration(days: 4)),
        points: 0,
        createdBy: 'admin',
        eventKind: EventKind.program,
      );
      expect(
        filterEventsInNextThirtyDays([program], now: now).map((e) => e.id),
        ['no-sessions'],
      );
    });
  });
}
