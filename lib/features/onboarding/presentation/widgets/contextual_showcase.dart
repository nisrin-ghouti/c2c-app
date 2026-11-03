import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../../core/accessibility/accessibility_controller.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/guided_matching_tour_controller.dart';

/// App-styled single-step spotlight used by every contextual (non-Home,
/// non-Meeting) demo — keeps title/description styling, tooltip shape, and
/// the single "Got it" dismiss action consistent across all of them instead
/// of repeating the same style block at every call site. Deliberately does
/// NOT touch `HomeCoachMarkKeys`' Showcase widgets, which keep the
/// library's plain defaults exactly as before.
///
/// Wrap the element to spotlight with this instead of a bare [Showcase];
/// starting the tour (`ShowcaseView.get().startShowCase([key])`) and
/// persisting "seen" state stays the caller's responsibility, same as the
/// existing Home coach-mark pattern.
class ContextualShowcase extends ConsumerStatefulWidget {
  const ContextualShowcase({
    super.key,
    required this.showcaseKey,
    required this.title,
    required this.description,
    required this.child,
    this.isLastStep = true,
  });

  final GlobalKey showcaseKey;
  final String title;
  final String description;
  final Widget child;

  /// False for every step of a multi-step contextual demo except the final
  /// one, which changes the button from "Got it" to "Next".
  ///
  /// Next advances one step. Close dismisses the whole demo — that is what
  /// the user asked for — and the existing dismiss listener marks it seen.
  final bool isLastStep;

  @override
  ConsumerState<ContextualShowcase> createState() => _ContextualShowcaseState();
}

class _ContextualShowcaseState extends ConsumerState<ContextualShowcase> {
  bool _wasOnScreen = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reduceMotion = ref.watch(accessibilitySettingsProvider).reduceMotion;

    // Dismiss THIS demo when its own screen leaves the screen.
    //
    // The overlay lives in the app-level Overlay, so it survives a tab switch.
    // A demo that started legitimately on a visible screen therefore FOLLOWS
    // the user: they switch tabs and the barrier is still up, now pointing at
    // an offstage target, with no reachable tooltip and every tap absorbed.
    // Starting is already gated on visibility in `startContextualDemoOnce`;
    // this handles the other half.
    //
    // The active-key check is essential. Dismissing whatever happens to be
    // running would let an unrelated widget kill the main tour: moving from
    // Matches to Scan takes the Matches branch offstage, and a blind dismiss
    // there tore down the tour step that had just started on Scan — the tour
    // then simply ended, which is what it did after the report step.
    final onScreen = TickerMode.of(context);
    if (_wasOnScreen && !onScreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final view = ShowcaseView.get();
        if (view.getActiveShowcaseKey == widget.showcaseKey) view.dismiss();
      });
    }
    _wasOnScreen = onScreen;

    final showcaseKey = widget.showcaseKey;
    final title = widget.title;
    final description = widget.description;
    final isLastStep = widget.isLastStep;
    final child = widget.child;

    return Showcase.withWidget(
      key: showcaseKey,
      // Barrier taps used to advance the demo, so tapping the dimmed page
      // closed a one-step spotlight and marked it seen. Got it and Close are
      // the only ways out.
      disableBarrierInteraction: true,
      disableMovingAnimation: reduceMotion,
      targetBorderRadius: BorderRadius.circular(16),
      overlayColor: AppColors.foreground,
      overlayOpacity: 0.55,
      container: _TourTooltip(
        title: title,
        description: description,
        actionsAlignment: MainAxisAlignment.end,
        onClose: ShowcaseView.get().dismiss,
        nextLabel: isLastStep ? l10n.actionGotIt : l10n.tutorialNextAction,
      ),
      child: child,
    );
  }
}

/// Like [ContextualShowcase], but for a *tap-gated* tour step — no "Got it"
/// button, and the rest of the screen is blocked from interaction. The user
/// must tap the spotlighted element itself to advance: that both runs
/// [onTap] and dismisses this step, since real gestures on the target still
/// pass through underneath the showcase overlay to whatever's actually
/// there (e.g. a real button press, a real nav-tab switch). Used for
/// walkthrough steps that should actively lead the user somewhere rather
/// than just narrate what's already in front of them.
class GuidedTapShowcase extends ConsumerWidget {
  const GuidedTapShowcase({
    super.key,
    required this.showcaseKey,
    required this.title,
    required this.description,
    required this.onTap,
    required this.child,
  });

  final GlobalKey showcaseKey;
  final String title;
  final String description;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = ref.watch(accessibilitySettingsProvider).reduceMotion;
    // Resolved while this widget is mounted. The tooltip lives in the overlay,
    // and by the time Close is tapped this context can already be deactivated.
    final container = ProviderScope.containerOf(context);

    return Showcase.withWidget(
      key: showcaseKey,
      container: _TourTooltip(
        title: title,
        description: description,
        onClose: () => closeMainTour(container),
      ),
      targetBorderRadius: BorderRadius.circular(16),
      overlayColor: AppColors.foreground,
      overlayOpacity: 0.55,
      disableMovingAnimation: reduceMotion,
      disableBarrierInteraction: true,
      onTargetClick: onTap,
      disposeOnTap: true,
      child: child,
    );
  }
}

/// App-styled step used by the main first-run tour. Unlike contextual demos,
/// it blocks the rest of the screen. Close sits at the top-left of the
/// tooltip; Previous and Next stay on the bottom row.
///
/// Narration-only steps (no [onTargetClick]) also block the highlighted
/// target itself from receiving real taps while this exact step is active.
/// showcaseview's own `disableDefaultTargetGestures: true` uses `IgnorePointer`
/// and leaks taps to the real widget underneath; `false` uses a translucent
/// gesture detector, which per Flutter's hit-testing rules *also* still lets
/// the tap continue through. Neither actually blocks the real widget, so this
/// wraps [child] in its own [AbsorbPointer] — driven by [ShowcaseView]'s
/// start/complete callbacks — which does.
class TourShowcase extends ConsumerStatefulWidget {
  const TourShowcase({
    super.key,
    required this.showcaseKey,
    required this.title,
    required this.description,
    required this.child,
    this.hidePrevious = false,
    this.hideNext = false,
    this.onTargetClick,
    this.disposeOnTap = false,
    this.showTooltip = true,
    this.tooltipPosition,
  });

  final GlobalKey showcaseKey;
  final String title;
  final String description;
  final Widget child;
  final bool hidePrevious;
  final bool hideNext;
  final VoidCallback? onTargetClick;
  final bool disposeOnTap;

  /// When false, this step contributes a highlight hole (merged with any
  /// other [TourShowcase]/[Showcase] sharing the same [showcaseKey]) but
  /// renders no tooltip content of its own — used to combine two on-screen
  /// areas into one step where only one of them should carry the title and
  /// description.
  final bool showTooltip;

  /// Passthrough to [Showcase.tooltipPosition] — lets a step's tooltip be
  /// pinned somewhere that won't cover its (or a shared-key sibling's)
  /// highlighted area, instead of the package's automatic placement.
  final TooltipPosition? tooltipPosition;

  @override
  ConsumerState<TourShowcase> createState() => _TourShowcaseState();
}

class _TourShowcaseState extends ConsumerState<TourShowcase> {
  bool _isActiveStep = false;

  void _onStart(int? index, GlobalKey key) {
    if (key == widget.showcaseKey && mounted) {
      setState(() => _isActiveStep = true);
    }
  }

  void _onComplete(int? index, GlobalKey key) {
    if (key == widget.showcaseKey && mounted) {
      setState(() => _isActiveStep = false);
    }
  }

  @override
  void initState() {
    super.initState();
    ShowcaseView.get().addOnStartCallback(_onStart);
    ShowcaseView.get().addOnCompleteCallback(_onComplete);
  }

  @override
  void dispose() {
    ShowcaseView.get().removeOnStartCallback(_onStart);
    ShowcaseView.get().removeOnCompleteCallback(_onComplete);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reduceMotion = ref.watch(accessibilitySettingsProvider).reduceMotion;
    // Resolved while this widget is mounted. The tooltip lives in the overlay,
    // and by the time Close is tapped this context can already be deactivated.
    final container = ProviderScope.containerOf(context);

    // Only narration-only steps need the real widget blocked: a step with a
    // real onTargetClick (e.g. "tap Open Wallet to continue") needs the tap
    // to keep reaching the real widget, that's how it advances the tour.
    final blockRealTaps = _isActiveStep && widget.onTargetClick == null;
    final child = AbsorbPointer(absorbing: blockRealTaps, child: widget.child);

    if (!widget.showTooltip) {
      return Showcase.withWidget(
        key: widget.showcaseKey,
        container: const SizedBox.shrink(),
        overlayColor: AppColors.foreground,
        overlayOpacity: 0.55,
        targetBorderRadius: BorderRadius.circular(16),
        disableMovingAnimation: reduceMotion,
        disableBarrierInteraction: true,
        disableDefaultTargetGestures: widget.onTargetClick == null,
        onTargetClick: widget.onTargetClick,
        disposeOnTap: widget.onTargetClick == null ? null : widget.disposeOnTap,
        tooltipPosition: widget.tooltipPosition,
        child: child,
      );
    }

    return Showcase.withWidget(
      key: widget.showcaseKey,
      container: _TourTooltip(
        title: widget.title,
        description: widget.description,
        onClose: () => closeMainTour(container),
        previousLabel: widget.hidePrevious ? null : l10n.tutorialBackAction,
        nextLabel: widget.hideNext ? null : l10n.tutorialNextAction,
      ),
      targetBorderRadius: BorderRadius.circular(16),
      overlayColor: AppColors.foreground,
      overlayOpacity: 0.55,
      disableMovingAnimation: reduceMotion,
      disableBarrierInteraction: true,
      disableDefaultTargetGestures: widget.onTargetClick == null,
      onTargetClick: widget.onTargetClick,
      disposeOnTap: widget.onTargetClick == null ? null : widget.disposeOnTap,
      tooltipPosition: widget.tooltipPosition,
      child: child,
    );
  }
}

/// Same card, type, and Back/Next buttons as the stock tooltip. Close is a
/// separate control in the top-left so it does not sit in that row.
class _TourTooltip extends StatelessWidget {
  const _TourTooltip({
    required this.title,
    required this.description,
    required this.onClose,
    this.previousLabel,
    this.nextLabel,
    this.actionsAlignment = MainAxisAlignment.spaceBetween,
  });

  final String title;
  final String description;
  final VoidCallback onClose;
  final String? previousLabel;
  final String? nextLabel;
  final MainAxisAlignment actionsAlignment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final previous = previousLabel;
    final next = nextLabel;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  l10n.actionClose,
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.mutedForeground,
            ),
          ),
          if (previous != null || next != null) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: actionsAlignment,
              children: [
                if (previous != null)
                  _TourStepButton(
                    label: previous,
                    filled: false,
                    onTap: () => ShowcaseView.get().previous(),
                  ),
                if (next != null)
                  _TourStepButton(
                    label: next,
                    filled: true,
                    onTap: () => ShowcaseView.get().next(force: true),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TourStepButton extends StatelessWidget {
  const _TourStepButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.transparent,
          borderRadius: const BorderRadius.all(Radius.circular(50)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: filled
                ? AppColors.primaryForeground
                : AppColors.mutedForeground,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
