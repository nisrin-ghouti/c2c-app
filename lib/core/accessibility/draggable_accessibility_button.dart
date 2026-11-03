import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../features/onboarding/domain/entities/demo_key.dart';
import '../../features/onboarding/presentation/controllers/demo_flags_controller.dart';
import '../../features/onboarding/presentation/controllers/home_coach_mark_controller.dart';
import '../../features/onboarding/presentation/home_coach_mark_keys.dart';
import '../../features/onboarding/presentation/widgets/contextual_showcase.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import 'accessibility_button_position_controller.dart';
import 'accessibility_panel.dart';

/// The floating accessibility button, draggable anywhere in the content area.
///
/// Tap opens the accessibility panel; a drag relocates it (position remembered
/// per device). Dragging it onto the remove target at the bottom hides it
/// entirely — users who don't want it always on screen can drop it there, and
/// re-enable it from Profile → Settings (where the panel also stays reachable).
///
/// Expects to be placed inside a [Stack] via `Positioned.fill` so it can
/// measure the area it may move within.
///
/// Target for the accessibility demo's own `Showcase` — shared (rather than
/// a private field on the state) so `maybeStartGuidedMatchingTour` can watch
/// for this specific showcase's dismissal and sequence the guided matching
/// walkthrough's Match-tab step to start only after it, instead of racing it.
final accessibilityDemoShowcaseKey = HomeCoachMarkKeys.accessibilityButton;

class DraggableAccessibilityButton extends ConsumerStatefulWidget {
  const DraggableAccessibilityButton({super.key});

  @override
  ConsumerState<DraggableAccessibilityButton> createState() =>
      _DraggableAccessibilityButtonState();
}

class _DraggableAccessibilityButtonState
    extends ConsumerState<DraggableAccessibilityButton> {
  /// Diameter of [FloatingActionButton.small].
  static const _buttonSize = 40.0;

  /// Keeps the button off the very edge, matching the old FAB's inset.
  static const _margin = 16.0;

  /// Remove-target geometry (a circle centered near the bottom of the area).
  static const _removeZoneSize = 64.0;
  static const _removeZoneBottomInset = 28.0;
  static const _removeCatchRadius = 56.0;

  /// Top-left in pixels while a drag is in progress; null when idle (the
  /// position then comes from the stored fraction).
  Offset? _dragPixels;

  // One-time "drag me / drag to hide" demo. This button is mounted globally
  // (inside `AppShell`, alongside every tab, including Home) so it can be
  // present at the exact same moment Home's own coach-mark tour starts —
  // a plain `!hasSeen` trigger would risk starting a second showcase while
  // Home's is still active. Polling briefly instead of hooking into a
  // global tour-finished callback (which would need to distinguish "which
  // tour just finished" for every showcase in the app) keeps this
  // self-contained: it only ever checks its own two pre-conditions and
  // backs off if any showcase is currently running, trying again shortly
  // after — no shared listener plumbing needed.
  Timer? _demoRetryTimer;
  bool _demoHandled = false;

  @override
  void initState() {
    super.initState();
    _demoRetryTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _maybeShowDemo(),
    );
  }

  void _maybeShowDemo() {
    if (_demoHandled || !mounted) return;
    if (!ref.read(accessibilityFloatingEnabledProvider)) return;
    if (!ref.read(hasSeenHomeCoachMarkProvider)) return;
    if (ref.read(hasSeenDemoProvider(DemoKey.accessibility))) {
      _demoHandled = true;
      _demoRetryTimer?.cancel();
      return;
    }
    if (ShowcaseView.get().isShowcaseRunning) return;
    _demoHandled = true;
    _demoRetryTimer?.cancel();
    ref.read(demoFlagsControllerProvider).markSeen(DemoKey.accessibility);
    ShowcaseView.get().startShowCase([accessibilityDemoShowcaseKey]);
  }

  Offset _removeZoneCenter(BoxConstraints c) => Offset(
    c.maxWidth / 2,
    c.maxHeight - _removeZoneBottomInset - _removeZoneSize / 2,
  );

  /// Center of the button given its top-left [pos].
  Offset _buttonCenter(Offset pos) =>
      Offset(pos.dx + _buttonSize / 2, pos.dy + _buttonSize / 2);

  bool _isOverRemoveZone(Offset buttonTopLeft, BoxConstraints c) {
    return (_buttonCenter(buttonTopLeft) - _removeZoneCenter(c)).distance <=
        _removeCatchRadius;
  }

  @override
  void dispose() {
    _demoRetryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Hidden when the user has turned the floating button off.
    if (!ref.watch(accessibilityFloatingEnabledProvider)) {
      return const SizedBox.shrink();
    }

    final stored = ref.watch(accessibilityButtonPositionProvider);
    // Default corner: bottom-end, which mirrors where the old FAB sat and so
    // flips for RTL locales.
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final fraction = stored ?? Offset(isRtl ? 0.0 : 1.0, 1.0);
    // Registers the Showcase target whenever the demo hasn't been seen yet;
    // `_maybeShowDemo`'s timer decides *when* it's safe to actually start it.
    final showAccessibilityDemo =
        !ref.watch(hasSeenHomeCoachMarkProvider) ||
        !ref.watch(hasSeenDemoProvider(DemoKey.accessibility));

    return LayoutBuilder(
      builder: (context, constraints) {
        final minX = _margin;
        final minY = _margin;
        final maxX = constraints.maxWidth - _buttonSize - _margin;
        final maxY = constraints.maxHeight - _buttonSize - _margin;

        // On a viewport too small to move within, pin it and skip dragging
        // rather than dividing by a zero-width range below.
        if (maxX <= minX || maxY <= minY) {
          return Stack(
            children: [
              Positioned(
                left: minX,
                top: minY,
                child: _button(l10n, showAccessibilityDemo),
              ),
            ],
          );
        }

        final resting = Offset(
          lerpDouble(minX, maxX, fraction.dx.clamp(0.0, 1.0))!,
          lerpDouble(minY, maxY, fraction.dy.clamp(0.0, 1.0))!,
        );
        final current = _dragPixels ?? resting;
        final left = current.dx.clamp(minX, maxX);
        final top = current.dy.clamp(minY, maxY);

        final dragging = _dragPixels != null;
        final overRemove =
            dragging && _isOverRemoveZone(Offset(left, top), constraints);

        return Stack(
          children: [
            // Remove target — only while dragging.
            if (dragging)
              Positioned(
                left: _removeZoneCenter(constraints).dx - _removeZoneSize / 2,
                top: _removeZoneCenter(constraints).dy - _removeZoneSize / 2,
                child: _RemoveTarget(
                  size: _removeZoneSize,
                  active: overRemove,
                  l10n: l10n,
                ),
              ),
            Positioned(
              left: left,
              top: top,
              child: GestureDetector(
                onPanStart: (_) =>
                    setState(() => _dragPixels = Offset(left, top)),
                onPanUpdate: (details) => setState(
                  () => _dragPixels =
                      (_dragPixels ?? Offset(left, top)) + details.delta,
                ),
                onPanEnd: (_) {
                  final dragged = _dragPixels;
                  setState(() => _dragPixels = null);
                  if (dragged == null) return;

                  final dropLeft = dragged.dx.clamp(minX, maxX);
                  final dropTop = dragged.dy.clamp(minY, maxY);

                  // Dropped on the remove target -> hide the button.
                  if (_isOverRemoveZone(
                    Offset(dropLeft, dropTop),
                    constraints,
                  )) {
                    ref
                        .read(accessibilityFloatingEnabledProvider.notifier)
                        .setEnabled(false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.accessibilityFloatingRemovedHint),
                      ),
                    );
                    return;
                  }

                  ref
                      .read(accessibilityButtonPositionProvider.notifier)
                      .setPosition(
                        Offset(
                          ((dropLeft - minX) / (maxX - minX)).clamp(0.0, 1.0),
                          ((dropTop - minY) / (maxY - minY)).clamp(0.0, 1.0),
                        ),
                      );
                },
                child: Opacity(
                  opacity: overRemove ? 0.4 : 1,
                  child: _button(l10n, showAccessibilityDemo),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _button(AppLocalizations l10n, bool showDemo) {
    final fab = FloatingActionButton.small(
      heroTag: 'accessibility',
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.foreground,
      tooltip: l10n.accessibilityPanelTitle,
      // The drag is owned by the GestureDetector above; the FAB only handles
      // the tap.
      onPressed: () => showAccessibilityPanel(context),
      child: const Icon(Icons.accessibility_new),
    );
    if (!showDemo) return fab;
    return TourShowcase(
      showcaseKey: accessibilityDemoShowcaseKey,
      title: l10n.tourAccessibilityTitle,
      description: l10n.tourAccessibilityDescription,
      child: fab,
    );
  }
}

/// The "drop here to hide" target shown at the bottom while dragging.
class _RemoveTarget extends StatelessWidget {
  const _RemoveTarget({
    required this.size,
    required this.active,
    required this.l10n,
  });

  final double size;
  final bool active;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: active
                ? AppColors.destructive
                : AppColors.destructive.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.destructive, width: 2),
          ),
          child: Icon(
            Icons.close,
            color: active ? Colors.white : AppColors.destructive,
            size: 26,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.actionRemove,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.destructive,
          ),
        ),
      ],
    );
  }
}
