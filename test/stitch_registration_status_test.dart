import 'package:c2c/features/events/domain/entities/campus_event.dart';
import 'package:c2c/features/events/domain/entities/event_kind.dart';
import 'package:c2c/features/events/domain/usecases/stitch_registration_status.dart';
import 'package:c2c/features/events/domain/entities/program_session_window.dart';
import 'package:flutter_test/flutter_test.dart';

CampusEvent _event({required String id, required EventKind kind}) {
  return CampusEvent(
    id: id,
    title: 'Event $id',
    category: null,
    location: null,
    startsAt: DateTime(2026, 1, 1, 10),
    endsAt: DateTime(2026, 1, 1, 12),
    points: 10,
    createdBy: 'host',
    eventKind: kind,
  );
}

/// Session counts in the shape `stitchRegistrationStatus` now takes. The
/// timestamps are irrelevant to registration status (they exist so date rules
/// can place a program by its sessions — see `ProgramSessionWindow`), so this
/// fills them with a fixed span and keeps each test about the count.
Map<String, ProgramSessionWindow> _sessions(Map<String, int> counts) {
  final base = DateTime.utc(2026, 1, 1);
  return {
    for (final entry in counts.entries)
      entry.key: ProgramSessionWindow(
        sessionCount: entry.value,
        firstStartsAt: base,
        lastEndsAt: base.add(const Duration(hours: 2)),
      ),
  };
}

void main() {
  group('stitchEventRegistrationStatus', () {
    test('a single event with an attendance row is attended', () {
      final result = stitchEventRegistrationStatus(
        _event(id: 'e1', kind: EventKind.single),
        registeredIds: {'e1'},
        attendedIds: {'e1'},
      );

      expect(result.registrationStatus, EventRegistrationStatus.attended);
      expect(result.sessionAttendance, isNull);
    });

    test('a program with one of three sessions scanned stays registered', () {
      final result = stitchEventRegistrationStatus(
        _event(id: 'p1', kind: EventKind.program),
        registeredIds: {'p1'},
        attendedIds: const {},
        attendedSessionCounts: const {'p1': 1},
        sessionCounts: _sessions(const {'p1': 3}),
      );

      expect(result.registrationStatus, EventRegistrationStatus.registered);
      expect(result.sessionAttendance?.attended, 1);
      expect(result.sessionAttendance?.total, 3);
      expect(result.sessionAttendance?.isComplete, isFalse);
    });

    test('a program is attended only once every session is scanned', () {
      final result = stitchEventRegistrationStatus(
        _event(id: 'p1', kind: EventKind.program),
        registeredIds: {'p1'},
        attendedIds: const {},
        attendedSessionCounts: const {'p1': 3},
        sessionCounts: _sessions(const {'p1': 3}),
      );

      expect(result.registrationStatus, EventRegistrationStatus.attended);
      expect(result.sessionAttendance?.isComplete, isTrue);
    });

    test(
      'scanning into a program without registering counts as taking part',
      () {
        final result = stitchEventRegistrationStatus(
          _event(id: 'p1', kind: EventKind.program),
          registeredIds: const {},
          attendedIds: const {},
          attendedSessionCounts: const {'p1': 1},
          sessionCounts: _sessions(const {'p1': 2}),
        );

        expect(result.registrationStatus, EventRegistrationStatus.registered);
      },
    );

    test('an empty program is never complete', () {
      final result = stitchEventRegistrationStatus(
        _event(id: 'p1', kind: EventKind.program),
        registeredIds: {'p1'},
        attendedIds: const {},
        attendedSessionCounts: const {},
        sessionCounts: _sessions(const {'p1': 0}),
      );

      expect(result.registrationStatus, EventRegistrationStatus.registered);
      expect(result.sessionAttendance?.isComplete, isFalse);
    });

    test('a legacy program-level attendance row still reads as attended', () {
      final result = stitchEventRegistrationStatus(
        _event(id: 'p1', kind: EventKind.program),
        registeredIds: {'p1'},
        attendedIds: {'p1'},
        attendedSessionCounts: const {},
        sessionCounts: _sessions(const {'p1': 2}),
      );

      expect(result.registrationStatus, EventRegistrationStatus.attended);
    });
  });
}
