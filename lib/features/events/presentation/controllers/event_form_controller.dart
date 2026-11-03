import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/event_draft.dart';
import '../../domain/entities/event_submit_result.dart';
import '../providers/events_providers.dart';

/// Shared UI state for the create/edit form — mirrors `AdminActionState`'s
/// loading/error/success shape.
class EventFormState {
  const EventFormState({
    this.loading = false,
    this.errorMessage,
    this.success = false,
  });

  final bool loading;
  final String? errorMessage;
  final bool success;

  static const initial = EventFormState();

  EventFormState loadingStarted() => const EventFormState(loading: true);

  EventFormState withError(String message) =>
      EventFormState(errorMessage: message);

  static const successState = EventFormState(success: true);
}

class EventFormController extends StateNotifier<EventFormState> {
  EventFormController(this._ref) : super(EventFormState.initial);

  final Ref _ref;

  Future<bool> submitCreate(
    EventDraft draft,
    String genericErrorMessage,
  ) async {
    state = state.loadingStarted();
    final result = await _ref.read(createEventProvider)(draft);
    if (result == EventSubmitResult.ok) {
      state = EventFormState.successState;
      _ref.invalidate(eventListProvider);
      _ref.invalidate(myEventsProvider);
      return true;
    }
    state = state.withError(genericErrorMessage);
    return false;
  }

  Future<bool> submitUpdate(
    String eventId,
    EventDraft draft,
    String genericErrorMessage,
  ) async {
    state = state.loadingStarted();
    final result = await _ref.read(updateEventProvider)(eventId, draft);
    if (result == EventSubmitResult.ok) {
      state = EventFormState.successState;
      _ref.invalidate(eventListProvider);
      _ref.invalidate(myEventsProvider);
      return true;
    }
    state = state.withError(genericErrorMessage);
    return false;
  }
}

final eventFormControllerProvider =
    StateNotifierProvider.autoDispose<EventFormController, EventFormState>((
      ref,
    ) {
      return EventFormController(ref);
    });
