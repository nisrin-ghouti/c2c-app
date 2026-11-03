import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../../onboarding/domain/entities/demo_key.dart';
import '../../../onboarding/presentation/controllers/demo_flags_controller.dart';
import '../../../onboarding/presentation/widgets/contextual_showcase.dart';
import '../../domain/entities/campus_event.dart';
import '../../domain/entities/event_scan_result.dart';
import '../controllers/event_scan_controller.dart';

/// Student-side "scan to check in" screen — copies `ScanCard`'s exact
/// visual structure (1:1 camera view, camera-icon header, manual-entry
/// fallback), but as its own routed screen rather than embedded in a tab,
/// since it's contextual to one specific event rather than always-available.
///
/// [event] is optional: opened from a specific event/program session it's
/// known upfront (and the manual student-ID fallback, which needs an event
/// to confirm attendance against, is shown); opened from the Scan tab's
/// general "Scan event QR" entry point it's null — any event's QR can be
/// scanned since the token itself encodes which event it belongs to, the
/// heading just reads generically, and the event-specific manual fallback
/// is hidden.
class EventAttendanceScanScreen extends ConsumerStatefulWidget {
  const EventAttendanceScanScreen({
    super.key,
    this.event,
    this.sessionTitle,
    this.sessionId,
  });

  final CampusEvent? event;

  /// Set when checking in to one session of a program, so a manual
  /// confirmation lands on that session rather than the program as a whole.
  final String? sessionId;

  /// Overrides the displayed heading for a Program session scan (the token
  /// itself already encodes which session it belongs to — this is display
  /// only, no extra scan logic needed).
  final String? sessionTitle;

  @override
  ConsumerState<EventAttendanceScanScreen> createState() =>
      _EventAttendanceScanScreenState();
}

class _EventAttendanceScanScreenState
    extends ConsumerState<EventAttendanceScanScreen> {
  String? _errorMessage;

  /// Shared with `ScanCard`'s own camera area — one `DemoKey`, shown once
  /// from whichever of the two entry points the student reaches first.
  final _cameraShowcaseKey = GlobalKey();

  @override
  void dispose() {
    super.dispose();
  }

  void _handleResult(EventScanResult? result, AppLocalizations l10n) {
    if (result == null || !mounted) return;

    if (result.status == EventScanStatus.confirmed) {
      // Immediate points-balance update without a page refresh, same
      // invalidate-on-success convention `EventActionsController.register`
      // already uses.
      ref.invalidate(homeDashboardProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventScanSuccess(result.points))),
      );
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _errorMessage = switch (result.status) {
        EventScanStatus.scanningClosed => l10n.eventScanningClosedMessage,
        EventScanStatus.expired => l10n.eventScanErrorExpired,
        EventScanStatus.alreadyScanned => l10n.eventScanErrorAlreadyScanned,
        EventScanStatus.notRegistered => l10n.eventScanErrorNotRegistered,
        EventScanStatus.invalid => l10n.eventScanErrorInvalid,
        EventScanStatus.confirmed => null,
      };
    });
  }

  Future<void> _handleDetect(
    BarcodeCapture capture,
    AppLocalizations l10n,
  ) async {
    if (capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue;
    if (value == null) return;
    final result = await ref
        .read(eventScanControllerProvider.notifier)
        .scanRawValue(value);
    _handleResult(result, l10n);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scanState = ref.watch(eventScanControllerProvider);

    if (!ref.watch(hasSeenDemoProvider(DemoKey.eventCheckIn))) {
      startContextualDemoOnce(
        context: context,
        ref: ref,
        key: DemoKey.eventCheckIn,
        showcaseKeys: [_cameraShowcaseKey],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.eventScanTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.sessionTitle ??
                    widget.event?.title ??
                    l10n.eventScanGenericHeading,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              // The preview is square, and this Column stretches its
              // children — so on a wide viewport (browser, iPad, landscape)
              // it demanded as much height as the window is wide and
              // overflowed the screen. Capping the width keeps it square
              // without letting it outgrow the available height; on a phone
              // this is narrower than the full width by only a few points.
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: ContextualShowcase(
                    showcaseKey: _cameraShowcaseKey,
                    title: l10n.demoEventCheckInTitle,
                    description: l10n.demoEventCheckInMessage,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            MobileScanner(
                              onDetect: (capture) =>
                                  _handleDetect(capture, l10n),
                            ),
                            if (scanState.isLoading)
                              Container(
                                color: AppColors.foreground.withValues(
                                  alpha: 0.4,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.destructive,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
