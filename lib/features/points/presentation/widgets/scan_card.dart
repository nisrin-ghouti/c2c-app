import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../events/domain/entities/event_scan_result.dart';
import '../../../events/presentation/controllers/event_scan_controller.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../../onboarding/domain/entities/demo_key.dart';
import '../../../onboarding/presentation/controllers/demo_flags_controller.dart';
import '../../../onboarding/presentation/controllers/guided_matching_tour_controller.dart';
import '../../../onboarding/presentation/widgets/contextual_showcase.dart';
import '../../../profile/presentation/providers/profile_providers.dart';

/// The scan card: a camera preview embedded directly on the Scan tab (no
/// extra button/navigation step) for checking into an event's QR — walk-up
/// or pre-registered, since scanning is itself enough to join (see
/// `scan_event_attendance`) — plus the student's permanent Student ID as a
/// fallback when a host can't scan the code.
///
/// Deliberately does NOT bring back a free-standing student-to-student
/// "scan anyone" meeting flow — that was removed as out of spec; meeting QR
/// exchange still only lives inside a scheduled meeting's own Meeting
/// Screen (`matches/presentation/screens/meeting_screen.dart`).
class ScanCard extends ConsumerStatefulWidget {
  const ScanCard({super.key});

  @override
  ConsumerState<ScanCard> createState() => _ScanCardState();
}

class _ScanCardState extends ConsumerState<ScanCard>
    with WidgetsBindingObserver {
  // App-managed camera controller. mobile_scanner won't reliably survive an
  // app pause/resume (or a Flutter hot restart, which orphans the native
  // camera) on its own — owning the controller lets us stop/restart it and,
  // crucially, dispose the old camera so a new one can acquire it.
  final _scannerController = MobileScannerController();
  String? _errorMessage;

  /// Shared with `EventAttendanceScanScreen`'s own camera area — whichever
  /// entry point the student reaches first shows the "how event points
  /// work" explanation; the other stays silent (one shared `DemoKey`).
  final _cameraShowcaseKey = GlobalKey();
  final _studentIdShowcaseKey = GlobalKey();
  bool _mainScanTourKicked = false;

  /// Set once a scan succeeds, to stop feeding further detections of the
  /// same still-visible QR into the RPC (mobile_scanner fires continuously
  /// while the code is in frame) — cleared by "Scan another".
  EventScanResult? _successResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // Fire-and-forget; swallow "already started"/permission errors.
        unawaited(_scannerController.start().catchError((_) {}));
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        unawaited(_scannerController.stop().catchError((_) {}));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  void _handleResult(EventScanResult? result, AppLocalizations l10n) {
    if (result == null || !mounted) return;

    if (result.status == EventScanStatus.confirmed) {
      ref.invalidate(homeDashboardProvider);
      setState(() {
        _errorMessage = null;
        _successResult = result;
      });
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
    if (_successResult != null) return;
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

    final mainScanTour =
        ref.watch(matchingTourStepProvider) ==
        MatchingTourStep.awaitingScanContent;
    if (!mainScanTour) _mainScanTourKicked = false;
    final eventCheckInSeen = ref.watch(
      hasSeenDemoProvider(DemoKey.eventCheckIn),
    );

    if (mainScanTour && !_mainScanTourKicked) {
      _mainScanTourKicked = true;
      ref.read(demoFlagsControllerProvider).markSeen(DemoKey.eventCheckIn);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final container = ProviderScope.containerOf(context, listen: false);
        final epoch = container.read(tourEpochProvider);
        if (!mainTourStillCurrent(container, epoch)) return;
        late VoidCallback finishListener;
        finishListener = () {
          // Deferred: showcaseview invokes these with `for (final cb in
          // _onFinishCallbacks)`, and mutating that list inside a callback throws
          // ConcurrentModificationError on the next moveNext(), silently skipping
          // every callback after this one — including the tour's own listener.
          scheduleMicrotask(
            () => ShowcaseView.get().removeOnFinishCallback(finishListener),
          );
          if (!mainTourStillCurrent(container, epoch)) return;
          container.read(matchingTourStepProvider.notifier).state =
              MatchingTourStep.awaitingBenefitsTab;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mainTourStillCurrent(container, epoch)) return;
            ShowcaseView.get().startShowCase([benefitsTabTourShowcaseKey]);
          });
        };
        ShowcaseView.get().addOnFinishCallback(finishListener);
        ShowcaseView.get().startShowCase([
          _cameraShowcaseKey,
          _studentIdShowcaseKey,
        ]);
      });
    } else if (!mainScanTour && !eventCheckInSeen) {
      startContextualDemoOnce(
        context: context,
        ref: ref,
        key: DemoKey.eventCheckIn,
        showcaseKeys: [_cameraShowcaseKey],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.scanEventCameraTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      l10n.scanEventGenericSubtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AspectRatio(
            aspectRatio: 1,
            child: _CameraViewport(
              controller: _scannerController,
              scanStateLoading: scanState.isLoading,
              successResult: _successResult,
              l10n: l10n,
              onDetect: (capture) => _handleDetect(capture, l10n),
              onScanAnother: () => setState(() => _successResult = null),
              viewfinderWrapper: (child) => mainScanTour
                  ? TourShowcase(
                      showcaseKey: _cameraShowcaseKey,
                      title: l10n.tourScanCameraTitle,
                      description: l10n.tourScanCameraDescription,
                      hidePrevious: true,
                      child: child,
                    )
                  : ContextualShowcase(
                      showcaseKey: _cameraShowcaseKey,
                      title: l10n.demoEventCheckInTitle,
                      description: l10n.demoEventCheckInMessage,
                      child: child,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.scanCameraPermissionHint,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 12),
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
          TourShowcase(
            showcaseKey: _studentIdShowcaseKey,
            title: l10n.tourStudentIdTitle,
            description: l10n.tourStudentIdDescription,
            child: const _StudentIdCard(),
          ),
        ],
      ),
    );
  }
}

class _CameraViewport extends StatelessWidget {
  const _CameraViewport({
    required this.controller,
    required this.scanStateLoading,
    required this.successResult,
    required this.l10n,
    required this.onDetect,
    required this.onScanAnother,
    required this.viewfinderWrapper,
  });

  final MobileScannerController controller;
  final bool scanStateLoading;
  final EventScanResult? successResult;
  final AppLocalizations l10n;
  final ValueChanged<BarcodeCapture> onDetect;
  final VoidCallback onScanAnother;
  final Widget Function(Widget child) viewfinderWrapper;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        alignment: Alignment.center,
        fit: StackFit.expand,
        children: [
          if (successResult == null) ...[
            MobileScanner(controller: controller, onDetect: onDetect),
            const IgnorePointer(
              child: CustomPaint(painter: _ViewfinderPainter()),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final side = constraints.maxWidth * 0.68;

                return Center(
                  child: SizedBox(
                    width: side,
                    height: side,
                    child: viewfinderWrapper(
                      const IgnorePointer(child: SizedBox.expand()),
                    ),
                  ),
                );
              },
            ),
            if (scanStateLoading)
              Container(
                color: AppColors.foreground.withValues(alpha: 0.4),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ] else
            _SuccessOverlay(
              result: successResult!,
              l10n: l10n,
              onScanAnother: onScanAnother,
            ),
        ],
      ),
    );
  }
}

/// Replaces the camera preview once a scan succeeds — the event title +
/// points earned, with a button to go again for another event.
class _SuccessOverlay extends StatelessWidget {
  const _SuccessOverlay({
    required this.result,
    required this.l10n,
    required this.onScanAnother,
  });

  final EventScanResult result;
  final AppLocalizations l10n;
  final VoidCallback onScanAnother;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.success.withValues(alpha: 0.1),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                size: 48,
                color: AppColors.success,
              ),
              const SizedBox(height: 10),
              if (result.eventTitle != null && result.eventTitle!.isNotEmpty)
                Text(
                  result.eventTitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                l10n.eventScanSuccess(result.points),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onScanAnother,
                child: Text(l10n.scanAnotherAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The classic QR-scanner viewfinder: a centered square with red corner
/// brackets and a faint full outline, painted over the camera preview.
class _ViewfinderPainter extends CustomPainter {
  const _ViewfinderPainter();

  static const _red = Color(0xFFF54B4B);

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide * 0.68;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: side,
      height: side,
    );
    final cornerLength = side * 0.16;

    // Faint full outline of the target area.
    final outline = Paint()
      ..color = _red.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      outline,
    );

    // Bold corner brackets.
    final corner = Paint()
      ..color = _red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void bracket(Offset c, Offset hDir, Offset vDir) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx + hDir.dx * cornerLength, c.dy + hDir.dy * cornerLength)
          ..lineTo(c.dx, c.dy)
          ..lineTo(
            c.dx + vDir.dx * cornerLength,
            c.dy + vDir.dy * cornerLength,
          ),
        corner,
      );
    }

    bracket(rect.topLeft, const Offset(1, 0), const Offset(0, 1));
    bracket(rect.topRight, const Offset(-1, 0), const Offset(0, 1));
    bracket(rect.bottomLeft, const Offset(1, 0), const Offset(0, -1));
    bracket(rect.bottomRight, const Offset(-1, 0), const Offset(0, -1));
  }

  @override
  bool shouldRepaint(_ViewfinderPainter oldDelegate) => false;
}

/// The student's permanent Student ID, shown so it can be read out to an event
/// host when scanning fails. Tap to copy.
class _StudentIdCard extends ConsumerWidget {
  const _StudentIdCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final studentId = ref.watch(myProfileProvider).valueOrNull?.studentId;
    if (studentId == null || studentId.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            l10n.scanStudentIdLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: studentId));
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.scanStudentIdCopied)));
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  studentId,
                  // Always LTR: a 10-digit ID must read the same in Hebrew and
                  // Arabic as the host sees it on their own screen.
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.copy,
                  size: 16,
                  color: AppColors.mutedForeground,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
