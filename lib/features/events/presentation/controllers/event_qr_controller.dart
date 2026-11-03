import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/event_qr_token.dart';
import '../providers/events_providers.dart';

enum EventQrPhase { idle, loading, active, error }

class EventQrState {
  const EventQrState({
    this.phase = EventQrPhase.idle,
    this.qrToken,
    required this.enabled,
  });

  final EventQrPhase phase;
  final EventQrToken? qrToken;
  final bool enabled;

  EventQrState copyWith({
    EventQrPhase? phase,
    EventQrToken? qrToken,
    bool? enabled,
  }) {
    return EventQrState(
      phase: phase ?? this.phase,
      qrToken: qrToken ?? this.qrToken,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// Drives the host/admin "Show QR" screen: unlike the 1:1 meeting QR (one
/// session, claimed once), an event's attendance QR keeps rotating every 10
/// seconds for as long as the screen is open, and scanning can be toggled
/// on/off independently of the rotation itself. [sessionId] scopes
/// everything to one Program session instead of the event itself.
class EventQrController extends StateNotifier<EventQrState> {
  EventQrController(
    this._ref,
    this._eventId,
    this._sessionId, {
    required bool initialEnabled,
  }) : super(EventQrState(enabled: initialEnabled));

  final Ref _ref;
  final String _eventId;
  final String? _sessionId;
  Timer? _ticker;

  Future<void> start() async {
    _ticker?.cancel();
    state = state.copyWith(phase: EventQrPhase.loading);
    await _rotate();
    _ticker = Timer.periodic(const Duration(seconds: 10), (_) => _rotate());
  }

  Future<void> _rotate() async {
    final token = await _ref.read(startEventQrProvider)(
      _eventId,
      sessionId: _sessionId,
    );
    if (token == null) {
      state = state.copyWith(phase: EventQrPhase.error);
      return;
    }
    state = state.copyWith(phase: EventQrPhase.active, qrToken: token);
  }

  Future<void> setEnabled(bool enabled) async {
    await _ref.read(setEventQrEnabledProvider)(
      _eventId,
      enabled,
      sessionId: _sessionId,
    );
    state = state.copyWith(enabled: enabled);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final eventQrControllerProvider = StateNotifierProvider.autoDispose
    .family<
      EventQrController,
      EventQrState,
      ({String eventId, String? sessionId, bool initialEnabled})
    >((ref, args) {
      return EventQrController(
        ref,
        args.eventId,
        args.sessionId,
        initialEnabled: args.initialEnabled,
      );
    });
