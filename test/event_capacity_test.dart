import 'package:c2c/features/events/domain/entities/campus_event.dart';
import 'package:c2c/features/events/domain/entities/event_kind.dart';
import 'package:c2c/features/events/domain/usecases/event_capacity.dart';
import 'package:flutter_test/flutter_test.dart';

CampusEvent _event({required String id, int? capacity}) {
  return CampusEvent(
    id: id,
    title: 'Event $id',
    category: null,
    location: null,
    startsAt: DateTime(2026, 4, 1, 10),
    endsAt: DateTime(2026, 4, 1, 12),
    points: 10,
    createdBy: 'host',
    eventKind: EventKind.single,
    capacity: capacity,
  );
}

void main() {
  group('EventCapacity', () {
    test('an uncapped event is never full', () {
      const capacity = EventCapacity(registered: 500, capacity: null);

      expect(capacity.isFull, isFalse);
      expect(capacity.remaining, isNull);
    });

    test('is full once registrations reach the cap', () {
      expect(const EventCapacity(registered: 29, capacity: 30).isFull, isFalse);
      expect(const EventCapacity(registered: 30, capacity: 30).isFull, isTrue);
    });

    test('stays full when registrations exceed the cap', () {
      // Possible after an organizer lowers the capacity below the number of
      // people already registered.
      const capacity = EventCapacity(registered: 35, capacity: 30);

      expect(capacity.isFull, isTrue);
      expect(capacity.remaining, 0);
    });

    test('reports the places left', () {
      expect(const EventCapacity(registered: 8, capacity: 30).remaining, 22);
    });

    test('a capacity of zero is treated as uncapped, not permanently full', () {
      expect(const EventCapacity(registered: 0, capacity: 0).isFull, isFalse);
    });

    test('raising the capacity reopens registration', () {
      const full = EventCapacity(registered: 30, capacity: 30);
      const raised = EventCapacity(registered: 30, capacity: 40);

      expect(full.isFull, isTrue);
      expect(raised.isFull, isFalse);
      expect(raised.remaining, 10);
    });

    test('a cancellation reopens registration', () {
      const full = EventCapacity(registered: 30, capacity: 30);
      const afterCancel = EventCapacity(registered: 29, capacity: 30);

      expect(full.isFull, isTrue);
      expect(afterCancel.isFull, isFalse);
      expect(afterCancel.remaining, 1);
    });
  });

  group('capacityOf', () {
    test('reads the count for the event out of the map', () {
      final capacity = capacityOf(_event(id: 'e1', capacity: 10), const {
        'e1': 4,
        'e2': 9,
      });

      expect(capacity.registered, 4);
      expect(capacity.capacity, 10);
      expect(capacity.isFull, isFalse);
    });

    test('a missing entry means nobody has registered', () {
      // The RPC omits events with no registrations rather than sending 0.
      final capacity = capacityOf(
        _event(id: 'quiet', capacity: 10),
        const <String, int>{},
      );

      expect(capacity.registered, 0);
      expect(capacity.isFull, isFalse);
    });

    test('a full event reads as full', () {
      final capacity = capacityOf(_event(id: 'e1', capacity: 3), const {
        'e1': 3,
      });

      expect(capacity.isFull, isTrue);
      expect(capacity.remaining, 0);
    });
  });
}
