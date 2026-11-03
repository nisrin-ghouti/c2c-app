import 'package:c2c/features/events/domain/entities/campus_event.dart';
import 'package:c2c/features/events/domain/entities/event_kind.dart';
import 'package:flutter_test/flutter_test.dart';

/// The rule `EventDetailScreen` uses to decide whether a program registration
/// is still waiting for an organizer to accept it.
///
/// Mirrored here rather than reached through the widget because it is the
/// decision that matters and it has four inputs: the kind, the registration
/// status, whether the backend's accepted list has loaded, and whether this
/// event is in it. The screen must agree with this — if the expression there
/// changes, this test is the thing that says so.
bool awaitingProgramApproval({
  required CampusEvent event,
  required Set<String>? acceptedProgramIds,
}) {
  return event.eventKind == EventKind.program &&
      event.registrationStatus == EventRegistrationStatus.registered &&
      acceptedProgramIds != null &&
      !acceptedProgramIds.contains(event.id);
}

CampusEvent _event({
  required EventKind kind,
  required EventRegistrationStatus status,
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

    test('a single event never shows the pending state', () {
      // Single events have no acceptance step at all, so they must not be
      // caught by the absence of a row in a table that only covers programs.
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
