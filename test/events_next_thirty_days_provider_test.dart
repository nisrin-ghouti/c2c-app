import 'package:c2c/features/events/domain/entities/campus_event.dart';
import 'package:c2c/features/events/domain/entities/event_kind.dart';
import 'package:c2c/features/events/presentation/providers/events_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// `eventsNextThirtyDaysProvider` is what BOTH the Home section and the
/// "See All" screen (`EventListScreen(onlyNextThirtyDays: true)`) read, so
/// this is the single place the window rule can be verified.
CampusEvent _event({
  required String id,
  required DateTime startsAt,
  required DateTime endsAt,
}) {
  return CampusEvent(
    id: id,
    title: id,
    category: 'General',
    location: 'Campus',
    startsAt: startsAt,
    endsAt: endsAt,
    points: 0,
    createdBy: 'admin',
    eventKind: EventKind.single,
  );
}

void main() {
  test('the next-30-days provider drops events outside the window', () async {
    final now = DateTime.now();
    final inWindowSoon = _event(
      id: 'tomorrow',
      startsAt: now.add(const Duration(days: 1)),
      endsAt: now.add(const Duration(days: 1, hours: 2)),
    );
    final inWindowEdge = _event(
      id: 'day-29',
      startsAt: now.add(const Duration(days: 29)),
      endsAt: now.add(const Duration(days: 29, hours: 2)),
    );
    final outsideWindow = _event(
      id: 'day-60',
      startsAt: now.add(const Duration(days: 60)),
      endsAt: now.add(const Duration(days: 60, hours: 2)),
    );
    // The shape two of the live events actually have: `ends_at` BEFORE
    // `starts_at`. It must be judged on its start date (far future) and
    // excluded, not accidentally let in by its earlier end date.
    final invertedDates = _event(
      id: 'inverted',
      startsAt: now.add(const Duration(days: 80)),
      endsAt: now.add(const Duration(days: 30)),
    );

    final container = ProviderContainer(
      overrides: [
        eventListProvider.overrideWith(
          (ref) async => [
            inWindowSoon,
            inWindowEdge,
            outsideWindow,
            invertedDates,
          ],
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(eventsNextThirtyDaysProvider.future);

    expect(
      result.map((e) => e.id),
      ['tomorrow', 'day-29'],
      reason: 'only events starting within 30 days, and not already finished',
    );
  });

  test('an event already under way still counts as in-window', () async {
    final now = DateTime.now();
    final running = _event(
      id: 'running',
      startsAt: now.subtract(const Duration(hours: 1)),
      endsAt: now.add(const Duration(hours: 1)),
    );
    final finished = _event(
      id: 'finished',
      startsAt: now.subtract(const Duration(days: 2)),
      endsAt: now.subtract(const Duration(days: 1)),
    );

    final container = ProviderContainer(
      overrides: [
        eventListProvider.overrideWith((ref) async => [running, finished]),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(eventsNextThirtyDaysProvider.future);
    expect(result.map((e) => e.id), ['running']);
  });
}
