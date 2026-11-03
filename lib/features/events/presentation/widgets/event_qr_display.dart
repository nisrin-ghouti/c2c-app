import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/event_qr_controller.dart';

/// Host/admin "Show QR" view — extends `MeetingQrDisplay`'s exact visual
/// container (20px-padded/24px-radius bordered white card, countdown text
/// below), but rotates every 10 seconds indefinitely instead of living for
/// one claim, and adds the enable/disable toggle the spec requires.
/// Decoupled from `CampusEvent` (just an id + optional session id) so the
/// same widget serves both a single event and one Program session.
class EventQrDisplay extends ConsumerStatefulWidget {
  const EventQrDisplay({
    super.key,
    required this.eventId,
    this.sessionId,
    required this.initialEnabled,
  });

  final String eventId;
  final String? sessionId;
  final bool initialEnabled;

  @override
  ConsumerState<EventQrDisplay> createState() => _EventQrDisplayState();
}

class _EventQrDisplayState extends ConsumerState<EventQrDisplay> {
  Timer? _countdownTicker;
  Duration _remaining = Duration.zero;

  ({String eventId, String? sessionId, bool initialEnabled}) get _args => (
    eventId: widget.eventId,
    sessionId: widget.sessionId,
    initialEnabled: widget.initialEnabled,
  );

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(eventQrControllerProvider(_args).notifier).start(),
    );
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    super.dispose();
  }

  void _startCountdown(DateTime expiresAt) {
    _countdownTicker?.cancel();
    void tick() {
      final remaining = expiresAt.difference(DateTime.now());
      if (!mounted) return;
      setState(
        () => _remaining = remaining.isNegative ? Duration.zero : remaining,
      );
    }

    tick();
    _countdownTicker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => tick(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    ref.listen(eventQrControllerProvider(_args), (previous, next) {
      final token = next.qrToken;
      if (token != null && token.token != previous?.qrToken?.token) {
        _startCountdown(token.expiresAt);
      }
    });

    final state = ref.watch(eventQrControllerProvider(_args));

    Widget body;
    if (!state.enabled) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_2, size: 40, color: AppColors.mutedForeground),
            const SizedBox(height: 12),
            Text(
              l10n.eventScanningClosedMessage,
              style: const TextStyle(color: AppColors.mutedForeground),
            ),
          ],
        ),
      );
    } else {
      switch (state.phase) {
        case EventQrPhase.idle:
        case EventQrPhase.loading:
          body = const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        case EventQrPhase.error:
          body = Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.eventQrLoadError,
              style: const TextStyle(color: AppColors.destructive),
            ),
          );
        case EventQrPhase.active:
          body = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: QrImageView(
                  data: state.qrToken!.qrValue,
                  size: 220,
                  backgroundColor: AppColors.card,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.eventQrRefreshesIn(_remaining.inSeconds.clamp(0, 10)),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          );
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.eventQrScanningLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: state.enabled,
                onChanged: (v) => ref
                    .read(eventQrControllerProvider(_args).notifier)
                    .setEnabled(v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          body,
        ],
      ),
    );
  }
}
