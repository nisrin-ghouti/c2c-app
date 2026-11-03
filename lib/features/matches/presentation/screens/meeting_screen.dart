import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../../core/accessibility/accessibility_controller.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../onboarding/domain/entities/demo_key.dart';
import '../../../onboarding/presentation/controllers/demo_flags_controller.dart';
import '../providers/scheduled_meeting_providers.dart';

/// The dedicated Meeting Screen for a scheduled one-on-one meeting.
///
/// Two sections, exactly as the reference: the student's own QR (which rotates
/// every 10s) and a camera to scan the other student's QR. Each section turns
/// green once its side is done — "Your QR Code" when the other student has
/// scanned you, "Scan the other student's QR" when you've scanned them. Points
/// are awarded server-side only after both directions complete.
class MeetingScreen extends ConsumerStatefulWidget {
  const MeetingScreen({
    super.key,
    required this.proposalId,
    required this.otherName,
    required this.scheduledAt,
    required this.endsAt,
  });

  final String proposalId;
  final String otherName;
  final DateTime scheduledAt;
  final DateTime endsAt;

  @override
  ConsumerState<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends ConsumerState<MeetingScreen>
    with WidgetsBindingObserver {
  final _scannerController = MobileScannerController();
  Timer? _rotateTimer;

  MeetingToken? _token;
  MeetingProgress _progress = const MeetingProgress(
    iScannedThem: false,
    theyScannedMe: false,
    completed: false,
  );

  bool _scanBusy = false;
  bool _celebrated = false;
  StreamSubscription? _checkinSub;

  // 2-step demo (Priority 1) — "Your QR Code" then "Scan the other
  // student's QR". `_demoAttempted` is a local, per-instance guard on top of
  // `startContextualDemoOnce`'s own `isShowcaseRunning` check: this screen's
  // `build()` reruns often (QR rotation, realtime check-in updates), and
  // without it every one of those rebuilds would re-schedule a trigger
  // attempt until the persisted flag catches up.
  final _yourQrShowcaseKey = GlobalKey();
  final _scanShowcaseKey = GlobalKey();
  bool _demoAttempted = false;

  void _maybeStartDemo() {
    if (_demoAttempted) return;
    _demoAttempted = true;
    startContextualDemoOnce(
      context: context,
      ref: ref,
      key: DemoKey.meeting,
      showcaseKeys: [_yourQrShowcaseKey, _scanShowcaseKey],
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final repo = ref.read(scheduledMeetingRepositoryProvider);
    // Initial state, then keep the QR fresh and watch for the other side.
    try {
      final progress = await repo.getProgress(widget.proposalId);
      if (mounted) setState(() => _progress = progress);
    } catch (_) {
      /* first paint tolerates a failed progress read */
    }

    await _rotate();
    _rotateTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _rotate(),
    );

    _checkinSub = repo.watchCheckins(widget.proposalId).listen((_) async {
      // Any check-in change → re-read authoritative progress.
      try {
        final progress = await repo.getProgress(widget.proposalId);
        if (mounted) setState(() => _progress = progress);
      } catch (_) {}
    });
  }

  Future<void> _rotate() async {
    // Once I've been scanned by them, my QR has done its job — stop rotating.
    if (_progress.theyScannedMe) return;
    try {
      final token = await ref
          .read(scheduledMeetingRepositoryProvider)
          .rotateToken(widget.proposalId);
      if (mounted) setState(() => _token = token);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_scannerController.start().catchError((_) {}));
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(_scannerController.stop().catchError((_) {}));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rotateTimer?.cancel();
    _checkinSub?.cancel();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture, AppLocalizations l10n) async {
    if (_scanBusy || _progress.iScannedThem) return;
    if (capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null || !raw.startsWith('c2c:meeting:')) return;

    setState(() => _scanBusy = true);
    try {
      final outcome = await ref
          .read(scheduledMeetingRepositoryProvider)
          .scan(raw);
      if (!mounted) return;
      if (outcome.status == MeetingScanStatus.ok && outcome.progress != null) {
        setState(() => _progress = outcome.progress!);
        _maybeCelebrate(l10n);
      } else if (outcome.status == MeetingScanStatus.ownCode) {
        _snack(l10n.meetingScanOwnCode);
      } else if (outcome.status == MeetingScanStatus.expired) {
        _snack(l10n.meetingScanExpired);
      }
    } catch (_) {
      if (mounted) _snack(l10n.meetingScanError);
    } finally {
      if (mounted) setState(() => _scanBusy = false);
    }
  }

  void _maybeCelebrate(AppLocalizations l10n) {
    if (_progress.completed && !_celebrated) {
      _celebrated = true;
      _snack(
        _progress.points > 0
            ? l10n.meetingCompletedPoints(_progress.points)
            : l10n.meetingCompletedNoPoints,
      );
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // toLocal(): these arrive as UTC, and formatting the raw fields would
  // print UTC wall-clock time to a student in campus time.
  String _time(DateTime utc) {
    final dt = utc.toLocal();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final windowOpen =
        now.isAfter(widget.scheduledAt) && now.isBefore(widget.endsAt);

    if (!windowOpen) {
      final notYetStarted = now.isBefore(widget.scheduledAt);
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(l10n.meetingInProgressTitle)),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    notYetStarted ? Icons.schedule : Icons.event_busy_outlined,
                    size: 48,
                    color: AppColors.mutedForeground,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    notYetStarted
                        ? l10n.meetingNotYetOpen
                        : l10n.meetingWindowEnded,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!ref.watch(hasSeenDemoProvider(DemoKey.meeting))) {
      _maybeStartDemo();
    }
    final reduceMotion = ref.watch(accessibilitySettingsProvider).reduceMotion;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.meetingInProgressTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  l10n.meetingWithLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Center(
                child: Text(
                  widget.otherName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 14,
                      color: AppColors.mutedForeground,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _time(widget.scheduledAt),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 1 — my QR. Green once the other student scanned it.
              Showcase(
                key: _yourQrShowcaseKey,
                title: l10n.demoMeetingStep1Title,
                description: l10n.demoMeetingStep1Message,
                titleTextStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.foreground,
                ),
                descTextStyle: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.mutedForeground,
                ),
                tooltipBackgroundColor: AppColors.card,
                tooltipBorderRadius: BorderRadius.circular(20),
                targetBorderRadius: BorderRadius.circular(20),
                overlayColor: AppColors.foreground,
                overlayOpacity: 0.55,
                disableMovingAnimation: reduceMotion,
                disableScaleAnimation: reduceMotion,
                tooltipActionConfig: const TooltipActionConfig(
                  position: TooltipActionPosition.inside,
                  alignment: MainAxisAlignment.end,
                ),
                tooltipActions: [
                  TooltipActionButton(
                    type: TooltipDefaultActionType.skip,
                    name: l10n.actionSkip,
                    backgroundColor: AppColors.muted,
                    textStyle: const TextStyle(
                      color: AppColors.mutedForeground,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  TooltipActionButton(
                    type: TooltipDefaultActionType.next,
                    name: l10n.actionNext,
                    backgroundColor: AppColors.primary,
                    textStyle: const TextStyle(
                      color: AppColors.primaryForeground,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
                child: _MeetingSection(
                  title: l10n.meetingYourQrTitle,
                  done: _progress.theyScannedMe,
                  child: _progress.theyScannedMe
                      ? _DoneMark(label: l10n.meetingSectionDone)
                      : (_token == null
                            ? const SizedBox(
                                height: 200,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: QrImageView(
                                      data: _token!.qrValue,
                                      size: 180,
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.meetingQrRotatingHint,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.mutedForeground,
                                    ),
                                  ),
                                ],
                              )),
                ),
              ),
              const SizedBox(height: 16),

              // Section 2 — scan them. Green once I've scanned them.
              Showcase(
                key: _scanShowcaseKey,
                title: l10n.demoMeetingStep2Title,
                description: l10n.demoMeetingStep2Message,
                titleTextStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.foreground,
                ),
                descTextStyle: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.mutedForeground,
                ),
                tooltipBackgroundColor: AppColors.card,
                tooltipBorderRadius: BorderRadius.circular(20),
                targetBorderRadius: BorderRadius.circular(20),
                overlayColor: AppColors.foreground,
                overlayOpacity: 0.55,
                disableMovingAnimation: reduceMotion,
                disableScaleAnimation: reduceMotion,
                tooltipActionConfig: const TooltipActionConfig(
                  position: TooltipActionPosition.inside,
                  alignment: MainAxisAlignment.end,
                ),
                tooltipActions: [
                  TooltipActionButton(
                    type: TooltipDefaultActionType.previous,
                    name: l10n.actionBack,
                    backgroundColor: AppColors.muted,
                    textStyle: const TextStyle(
                      color: AppColors.mutedForeground,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  TooltipActionButton(
                    type: TooltipDefaultActionType.next,
                    name: l10n.actionGotIt,
                    backgroundColor: AppColors.primary,
                    textStyle: const TextStyle(
                      color: AppColors.primaryForeground,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
                child: _MeetingSection(
                  title: l10n.meetingScanOtherTitle,
                  done: _progress.iScannedThem,
                  child: _progress.iScannedThem
                      ? _DoneMark(label: l10n.meetingSectionDone)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: 220,
                            child: MobileScanner(
                              controller: _scannerController,
                              onDetect: (capture) => _onDetect(capture, l10n),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 15,
                    color: AppColors.mutedForeground,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.meetingBothActionsHint,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A titled card that tints green with a check when its action is done —
/// matching the reference's amber-pending / green-complete sections.
class _MeetingSection extends StatelessWidget {
  const _MeetingSection({
    required this.title,
    required this.done,
    required this.child,
  });

  final String title;
  final bool done;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final accent = done ? AppColors.success : const Color(0xFFB8860B);
    final bg = done
        ? AppColors.success.withValues(alpha: 0.10)
        : const Color(0xFFB8860B).withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
              if (done) ...[
                const SizedBox(width: 6),
                Icon(Icons.check_circle, size: 18, color: AppColors.success),
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DoneMark extends StatelessWidget {
  const _DoneMark({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, size: 48, color: AppColors.success),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
