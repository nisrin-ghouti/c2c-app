import 'package:c2c/features/events/domain/entities/campus_event.dart';
import 'package:c2c/features/events/domain/usecases/event_capacity.dart';
import 'package:flutter_test/flutter_test.dart';

CampusEvent _event({int? capacity, bool registrationClosed = false}) {
  return CampusEvent(
    id: 'e1',
    title: 'Event',
    category: 'General',
    location: 'Campus',
    startsAt: DateTime.utc(2026, 12, 1),
    endsAt: DateTime.utc(2026, 12, 2),
    points: 0,
    createdBy: 'admin',
    capacity: capacity,
    registrationClosed: registrationClosed,
  );
}

void main() {
  group('registrationBlocked', () {
    test('open event with places is not blocked', () {
      expect(
        registrationBlocked(_event(capacity: 10), const {'e1': 3}),
        isFalse,
      );
    });

    test('blocked when the places have run out', () {
      expect(
        registrationBlocked(_event(capacity: 10), const {'e1': 10}),
        isTrue,
      );
    });

    test('blocked when an admin closed it, even with places left', () {
      // The case the external card button got wrong: capacity says there is
      // room, so the button stayed live and the server refused the tap.
      expect(
        registrationBlocked(
          _event(capacity: 100, registrationClosed: true),
          const {'e1': 3},
        ),
        isTrue,
      );
    });

    test('blocked when an admin closed an UNCAPPED event', () {
      // No capacity at all, so `isFull` can never be true — closure is the
      // only thing that can block it.
      expect(
        registrationBlocked(
          _event(registrationClosed: true),
          const {'e1': 500},
        ),
        isTrue,
      );
    });

    test('reopening restores registration', () {
      expect(
        registrationBlocked(
          _event(capacity: 100, registrationClosed: false),
          const {'e1': 3},
        ),
        isFalse,
      );
    });

    test('an uncapped open event is never blocked, whatever the count', () {
      expect(registrationBlocked(_event(), const {'e1': 9999}), isFalse);
    });

    test('a missing count entry means nobody has registered', () {
      expect(registrationBlocked(_event(capacity: 1), const {}), isFalse);
    });
  });
}
