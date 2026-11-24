import 'package:c2c/features/events/domain/entities/acceptance_mode.dart';
import 'package:c2c/features/events/domain/entities/campus_event.dart';
import 'package:c2c/features/events/domain/entities/event_kind.dart';
import 'package:flutter_test/flutter_test.dart';

/// The rule `EventDetailScreen` uses to decide whether a registration is
/// still waiting for an organizer to accept it. The screen calls
/// [CampusEvent.isAwaitingAcceptance]; this test is that rule.
bool awaitingProgramApproval({
  required CampusEvent event,
  required Set<String>? acceptedProgramIds,
}) {
  return event.isAwaitingAcceptance(acceptedProgramIds);
}

CampusEvent _event({
  required EventKind kind,
  required EventRegistrationStatus status,
  AcceptanceMode? acceptanceMode,
  String id = 'p1',
}) {
  return CampusEvent(
    id: id,
    title: 'Program',
    category: 'General',
    location: 'Campus',
    startsAt: DateTime.utc(2026, 11, 1),
    endsAt: DateTime.utc(2026, 12, 1),
    points: 0,
    createdBy: 'admin',
    eventKind: kind,
    acceptanceMode: acceptanceMode,
    registrationStatus: status,
  );
}

void main() {
  group('awaiting program approval', () {
    test('registered for a program, not yet accepted -> pending', () {
      expect(
        awaitingProgramApproval(
          event: _event(
            kind: EventKind.program,
            status: EventRegistrationStatus.registered,
          ),
          acceptedProgramIds: const <String>{},
        ),
        isTrue,
      );
    });

    test('registered AND accepted -> not pending', () {
      expect(
        awaitingProgramApproval(
          event: _event(
            kind: EventKind.program,
            status: EventRegistrationStatus.registered,
          ),
          acceptedProgramIds: const {'p1'},
        ),
        isFalse,
      );
    });

    test('accepted onto a DIFFERENT program is still pending for this one', () {
      expect(
        awaitingProgramApproval(
          event: _event(
            kind: EventKind.program,
            status: EventRegistrationStatus.registered,
          ),
          acceptedProgramIds: const {'some-other-program'},
        ),
        isTrue,
      );
    });

    test('an auto-accept one-time event never shows the pending state', () {
      expect(
        awaitingProgramApproval(
          event: _event(
            kind: EventKind.single,
            status: EventRegistrationStatus.registered,
          ),
          acceptedProgramIds: const <String>{},
        ),
        isFalse,
      );
    });

    test('a one-time event that requires approval, not yet accepted -> pending', () {
      expect(
        awaitingProgramApproval(
          event: _event(
            kind: EventKind.single,
            acceptanceMode: AcceptanceMode.approval,
            status: EventRegistrationStatus.registered,
          ),
          acceptedProgramIds: const <String>{},
        ),
        isTrue,
      );
    });

    test('an auto-accept program is not pending', () {
      expect(
        awaitingProgramApproval(
          event: _event(
            kind: EventKind.program,
            acceptanceMode: AcceptanceMode.auto,
            status: EventRegistrationStatus.registered,
          ),
          acceptedProgramIds: const <String>{},
        ),
        isFalse,
      );
    });

    test('not registered -> not pending', () {
      expect(
        awaitingProgramApproval(
          event: _event(
            kind: EventKind.program,
            status: EventRegistrationStatus.notRegistered,
          ),
          acceptedProgramIds: const <String>{},
        ),
        isFalse,
      );
    });

    test('already attended -> not pending', () {
      expect(
        awaitingProgramApproval(
          event: _event(
            kind: EventKind.program,
            status: EventRegistrationStatus.attended,
          ),
          acceptedProgramIds: const <String>{},
        ),
        isFalse,
      );
    });

    test('while the accepted list is still loading -> not pending', () {
      // Null means "we do not know yet". Treating it as pending would flash a
      // status at every student opening any program before the lookup lands.
      expect(
        awaitingProgramApproval(
          event: _event(
            kind: EventKind.program,
            status: EventRegistrationStatus.registered,
          ),
          acceptedProgramIds: null,
        ),
        isFalse,
      );
    });
  });

  group('registrationClosed', () {
    test('defaults to false so pre-0070 rows stay registerable', () {
      expect(
        _event(
          kind: EventKind.single,
          status: EventRegistrationStatus.notRegistered,
        ).registrationClosed,
        isFalse,
      );
    });

    test('survives copyWith, which the stitch step runs on every event', () {
      final closed = CampusEvent(
        id: 'e1',
        title: 'Closed event',
        category: 'General',
        location: 'Campus',
        startsAt: DateTime.utc(2026, 11, 1),
        endsAt: DateTime.utc(2026, 11, 2),
        points: 0,
        createdBy: 'admin',
        registrationClosed: true,
      );
      expect(
        closed
            .copyWith(registrationStatus: EventRegistrationStatus.registered)
            .registrationClosed,
        isTrue,
      );
    });
  });
}
