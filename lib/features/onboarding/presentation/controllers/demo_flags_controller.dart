import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../../core/storage/shared_preferences_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/demo_key.dart';

/// Whether the current user has already seen a given contextual demo —
/// `true` (never shown) while signed out, since there's nothing to gate yet.
/// Watches `authSessionProvider` (same idiom as `profileGateProvider`/
/// `isStudentEligibleProvider`) so switching accounts on the same device
/// re-evaluates instead of reusing the previous user's cached result.
final hasSeenDemoProvider = Provider.family<bool, DemoKey>((ref, key) {
  ref.watch(authSessionProvider);
  final userId = ref.watch(currentAuthSessionProvider).userId;
  if (userId == null) return true;
  return ref.watch(appPreferencesProvider).hasSeenDemo(userId, key.storageKey);
});

/// Marks a contextual demo seen for the current user. A no-op while signed
/// out (nothing to persist against).
class DemoFlagsController {
  DemoFlagsController(this._ref);

  final Ref _ref;

  Future<void> markSeen(DemoKey key) async {
    final userId = _ref.read(currentAuthSessionProvider).userId;
    if (userId == null) return;
    await _ref
        .read(appPreferencesProvider)
        .setHasSeenDemo(userId, key.storageKey);
    _ref.invalidate(hasSeenDemoProvider(key));
  }

  Future<void> resetSelected(Iterable<DemoKey> keys) async {
    final userId = _ref.read(currentAuthSessionProvider).userId;
    if (userId == null) return;
    for (final key in keys) {
      await _ref.read(appPreferencesProvider).resetDemo(userId, key.storageKey);
      _ref.invalidate(hasSeenDemoProvider(key));
    }
  }

  /// Un-marks every contextual demo as seen — "Replay Tutorials" in
  /// Settings. Each demo simply reappears next time its own screen is
  /// visited; unlike "Replay App Introduction" this doesn't navigate
  /// anywhere or touch the onboarding/Home-coach-mark flags.
  Future<void> resetAll() async {
    final userId = _ref.read(currentAuthSessionProvider).userId;
    if (userId == null) return;
    await _ref.read(appPreferencesProvider).resetAllDemos(userId);
    for (final key in DemoKey.values) {
      _ref.invalidate(hasSeenDemoProvider(key));
    }
  }
}

final demoFlagsControllerProvider = Provider((ref) => DemoFlagsController(ref));

/// Starts a one-shot contextual showcase after the current frame, the
/// standard trigger for every Priority-1/2 demo in this feature. Guards
/// against:
///  - the widget being gone by the time the frame callback fires
///  - starting while another tour (Home's, or a different contextual one)
///    is already active, so demos never stack — the caller's own
///    `!hasSeenX` gate means this simply gets tried again on the next
///    rebuild rather than being lost.
///
/// Marks the flag seen at trigger time (not on tour completion) — the same
/// convention `HomeCoachMarkController`/`OnboardingTutorialController`
/// already use, kept for consistency rather than introducing a second rule.
final Set<DemoKey> _scheduledContextualDemos = <DemoKey>{};

void startContextualDemoOnce({
  required BuildContext context,
  required WidgetRef ref,
  required DemoKey key,
  required List<GlobalKey> showcaseKeys,
}) {
  // Rebuilds while async content is resolving must not queue the same demo
  // multiple times. In particular this prevents the first visit to Champions,
  // Notifications and a digital card from getting stuck on Showcase's target
  // loader until an unrelated tap forces another layout pass.
  if (_scheduledContextualDemos.contains(key)) return;
  _scheduledContextualDemos.add(key);

  void attempt(int triesLeft) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) {
        _scheduledContextualDemos.remove(key);
        return;
      }

      // `currentContext` is ALWAYS null here: showcaseview's Showcase takes
      // its GlobalKey as `required GlobalKey key` but never forwards it to
      // `super(key: ...)` — it is only a registry id, never attached to an
      // Element. Testing it meant `targetsReady` was never true, so every
      // contextual demo retried 30 times and then gave up silently. Ask the
      // package's own registry instead, as `benefits_screen.dart` does.
      final targetsReady = showcaseKeys.every(
        (showcaseKey) => ShowcaseView.get().isTargetRendered(showcaseKey),
      );

      // Only run when this screen is actually on screen.
      //
      // StatefulShellRoute.indexedStack keeps every branch BUILT — go_router
      // wraps the inactive ones in Offstage + TickerMode(enabled: false) — so
      // a screen left on another tab's navigator stack keeps calling build()
      // while the user is elsewhere. Without this guard, resetting a demo flag
      // (as "replay tour" does) fires that screen's demo immediately, and the
      // showcase then runs against an offstage target: a full-screen barrier
      // with disableBarrierInteraction and nothing to tap, which reads as the
      // app freezing.
      //
      // TickerMode covers the inactive-branch case; isCurrent covers a route
      // buried under another push within the same branch.
      final onScreen =
          TickerMode.of(context) && (ModalRoute.of(context)?.isCurrent ?? true);

      // Wait for a push transition to settle. showcaseview measures its
      // target once, when the showcase starts, and never re-measures — so a
      // demo on a freshly pushed route (the digital card, the report button)
      // captures a mid-slide position and the spotlight lands offset from the
      // element, or misses it entirely. The existing retry loop is long
      // enough (30 x 120ms) to outlast a page transition.
      final animation = ModalRoute.of(context)?.animation;
      final transitionSettled =
          animation == null ||
          animation.status == AnimationStatus.completed ||
          animation.status == AnimationStatus.dismissed;

      if (ShowcaseView.get().isShowcaseRunning ||
          !onScreen ||
          !targetsReady ||
          !transitionSettled) {
        if (triesLeft <= 0) {
          _scheduledContextualDemos.remove(key);
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 120));
        attempt(triesLeft - 1);
        // Guarantee the frame the next attempt is waiting for.
        //
        // `addPostFrameCallback` runs after the NEXT frame — and if nothing
        // schedules one, there is no next frame and the callback simply never
        // fires. A pushed detail screen is static once its transition settles
        // (no animation, no ticker), so the retry chain stalled here instead
        // of retrying: the demo never appeared, and the queued callback was
        // then run by the first unrelated frame — a scroll, a tap, a rebuild
        // from an async provider resolving — which is exactly the reported
        // "shows up on the second open, 5-8 seconds in". The digital card hit
        // it every time because its showcase target only registers once the
        // route is fully laid out, so attempt #1 always has to retry.
        WidgetsBinding.instance.ensureVisualUpdate();
        return;
      }

      _scheduledContextualDemos.remove(key);
      if (!context.mounted) return;

      // Mark seen when the user actually finishes or dismisses the demo, not
      // the moment it starts.
      //
      // Marking on start meant any demo cut short — by a rebuild that
      // unmounted its target, a navigation, anything — was silently consumed
      // forever, having shown the user nothing. There is no in-app way back:
      // `DemoFlagsController.resetAll` exists but has no call site, and the
      // tour replay only resets four of the keys.
      //
      // Both callbacks are needed: finishing runs `onFinish`, while skipping
      // or tapping the barrier runs `onDismiss` instead. Anything that ends
      // the showcase without either — an unmounted target — deliberately
      // leaves the demo unseen so it gets another chance.
      final showcaseView = ShowcaseView.get();
      late final VoidCallback onFinish;
      late final OnDismissCallback onDismiss;

      var handled = false;
      void markSeenOnce() {
        if (handled) return;
        handled = true;
        // Deferred: showcaseview invokes these with `for (final cb in
        // _onFinishCallbacks)`, and mutating that list inside a callback
        // throws ConcurrentModificationError on the next moveNext(), silently
        // skipping every callback after this one — which is how adding this
        // listener started killing the main tour's own finish handler.
        scheduleMicrotask(() {
          showcaseView.removeOnFinishCallback(onFinish);
          showcaseView.removeOnDismissCallback(onDismiss);
        });
        ref.read(demoFlagsControllerProvider).markSeen(key);
      }

      onFinish = markSeenOnce;
      onDismiss = (_) => markSeenOnce();

      showcaseView.addOnFinishCallback(onFinish);
      showcaseView.addOnDismissCallback(onDismiss);
      showcaseView.startShowCase(showcaseKeys);
    });
  }

  attempt(30);
}
