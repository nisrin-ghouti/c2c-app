import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/event_action_result.dart';
import '../../domain/entities/event_cancel_result.dart';
import '../providers/events_providers.dart';

/// Tracks which event ids currently have an in-flight register/cancel/
/// delete request, so only that event's button shows a spinner.
class EventActionsController extends StateNotifier<Set<String>> {
  EventActionsController(this._ref) : super(const {});

  final Ref _ref;

  bool isBusy(String eventId) => state.contains(eventId);

  void _refreshLists() {
    _ref.invalidate(eventListProvider);
    _ref.invalidate(myEventsProvider);
    // The detail screen follows the live row through `eventByIdProvider`, so
    // without this the viewer's own register/cancel changed nothing on the
    // screen they just tapped: the CTA kept rendering the snapshot it was
    // pushed with — still offering Register — until the screen was closed and
    // reopened. Family: invalidating the provider clears every argument.
    _ref.invalidate(eventByIdProvider);
    // The viewer's own register/cancel moves the registration count, which is
    // what decides whether an event reads as full. `eventListProvider`'s
    // dependents recompute on their own; this family doesn't watch it.
    _ref.invalidate(eventRegistrationCountProvider);
    // Registering for a program makes the viewer a registrant who is not yet
    // accepted — exactly the "waiting for approval" state — so this has to be
    // re-read for the CTA to settle on it without a restart.
    _ref.invalidate(myAcceptedProgramIdsProvider);
  }

  Future<EventActionResult> register(String eventId) async {
    state = {...state, eventId};
    try {
      final result = await _ref.read(registerForEventProvider)(eventId);
      if (result == EventActionResult.ok) _refreshLists();
      return result;
    } finally {
      state = {...state}..remove(eventId);
    }
  }

  Future<EventCancelResult> cancel(String eventId) async {
    state = {...state, eventId};
    try {
      final result = await _ref.read(cancelEventRegistrationProvider)(eventId);
      if (result == EventCancelResult.ok) _refreshLists();
      return result;
    } finally {
      state = {...state}..remove(eventId);
    }
  }

  Future<bool> delete(String eventId) async {
    state = {...state, eventId};
    try {
      await _ref.read(deleteEventProvider)(eventId);
      _refreshLists();
      return true;
    } catch (_) {
      return false;
    } finally {
      state = {...state}..remove(eventId);
    }
  }
}

final eventActionsControllerProvider =
    StateNotifierProvider.autoDispose<EventActionsController, Set<String>>((
      ref,
    ) {
      return EventActionsController(ref);
    });
