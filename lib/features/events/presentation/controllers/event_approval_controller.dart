import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/campus_event.dart';
import '../../domain/entities/event_submit_result.dart';
import '../providers/events_providers.dart';

/// Backs the admin's pending-events approval queue — one loading/error/data
/// state, with approve/reject re-fetching the queue afterward (same
/// re-fetch-on-mutate convention as `AdminUsersController`).
class EventApprovalController
    extends StateNotifier<AsyncValue<List<CampusEvent>>> {
  EventApprovalController(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _ref.read(getPendingEventsProvider)());
  }

  Future<void> refresh() => _load();

  Future<EventSubmitResult> approve(String eventId) async {
    final result = await _ref.read(approveEventProvider)(eventId);
    if (result == EventSubmitResult.ok) {
      await _load();
      _ref.invalidate(eventListProvider);
    }
    return result;
  }

  Future<EventSubmitResult> reject(String eventId, String reason) async {
    final result = await _ref.read(rejectEventProvider)(eventId, reason);
    if (result == EventSubmitResult.ok) await _load();
    return result;
  }
}

final eventApprovalControllerProvider =
    StateNotifierProvider.autoDispose<
      EventApprovalController,
      AsyncValue<List<CampusEvent>>
    >((ref) {
      return EventApprovalController(ref);
    });
