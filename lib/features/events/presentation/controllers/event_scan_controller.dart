import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/event_scan_result.dart';
import '../providers/events_providers.dart';

/// Mirrors `MeetingScanController` exactly — same repeated-detection guard,
/// same manual-code fallback shape — just calling `scan_event_attendance`
/// instead of `claim_meeting_session`.
class EventScanController extends StateNotifier<AsyncValue<void>> {
  EventScanController(this._ref) : super(const AsyncData(null));

  final Ref _ref;
  bool _handled = false;

  bool get isBusy => _handled;

  Future<EventScanResult?> scanRawValue(String rawValue) async {
    if (!rawValue.startsWith('c2c:event:')) return null;
    return _scan(rawValue.replaceFirst('c2c:event:', ''));
  }

  /// The manual "enter code" fallback — the typed value *is* the token.
  Future<EventScanResult?> submitManualCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return null;
    return _scan(trimmed);
  }

  Future<EventScanResult?> _scan(String token) async {
    if (_handled) return null;
    _handled = true;
    state = const AsyncLoading();
    try {
      final result = await _ref.read(scanEventAttendanceProvider)(token);
      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    } finally {
      _handled = false;
    }
  }
}

final eventScanControllerProvider =
    StateNotifierProvider.autoDispose<EventScanController, AsyncValue<void>>((
      ref,
    ) {
      return EventScanController(ref);
    });
