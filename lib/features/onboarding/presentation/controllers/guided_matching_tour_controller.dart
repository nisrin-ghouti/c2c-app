import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../../core/storage/shared_preferences_provider.dart';
import '../../../matches/presentation/controllers/matches_controller.dart';
import '../../domain/entities/demo_key.dart';
import 'demo_flags_controller.dart';
import 'home_coach_mark_controller.dart';

/// Cross-screen state for the first-run step-by-step tour.
///
/// Local descriptive steps use Showcase's Previous/Next buttons. Navigation
/// steps are tap-gated: the overlay blocks the rest of the UI and only the
/// highlighted target can be pressed.
enum MatchingTourStep {
  none,

  /// No longer entered. Retained because a session persisted before this
  /// step was removed can still resume into it; `tour_resume_controller`
  /// maps it back onto the normal flow.
  awaitingMatchesIntro,
  awaitingMatchTab,
  awaitingCompatibilityDemo,
  awaitingViewProfileTap,
  awaitingReportDemo,
  awaitingScanTab,
  awaitingScanContent,
  awaitingBenefitsTab,
  awaitingBenefitsContent,
  awaitingWalletTap,
  awaitingWalletContent,
  awaitingProfileTab,
}

/// Incremented every time the tour is replayed.
///
/// The tour opens a match profile with an imperative
/// `Navigator.push(MaterialPageRoute(...))`, which go_router's
/// `goBranch(initialLocation: true)` cannot pop — it only restores a branch's
/// go_router location. So that profile stayed on top of the Matches branch,
/// and a later replay's Matches step landed on it instead of the list, with
/// none of its targets present. Screens pushed by the tour watch this and
/// dismiss themselves when it changes.
final tourGenerationProvider = StateProvider<int>((ref) => 0);

final matchingTourStepProvider = StateProvider<MatchingTourStep>(
  (ref) => MatchingTourStep.none,
);

/// Bumped by [closeMainTour]. Segment listeners capture the value when they
/// register and ignore a later finish if it has changed.
///
/// showcaseview keeps `onFinish` listeners after `dismiss()`. Without this,
/// closing the tour would leave the current segment's listener in place, and
/// the next showcase to finish — often a one-step "Got it" demo — would
/// start the following tour step.
final tourEpochProvider = StateProvider<int>((ref) => 0);

bool mainTourStillCurrent(ProviderContainer container, int epoch) =>
    container.read(tourEpochProvider) == epoch;

/// Ends the first-run tour and keeps it from resuming on the next launch.
///
/// Replay App Introduction in Settings still starts it over: that path
/// clears the seen flag on its own.
void closeMainTour(ProviderContainer container) {
  container.read(tourEpochProvider.notifier).state++;
  final view = ShowcaseView.get();
  if (view.isShowcaseRunning) view.dismiss();
  container.read(matchingTourStepProvider.notifier).state =
      MatchingTourStep.none;
  container.read(homeCoachMarkControllerProvider.notifier).markSeen();
  container.read(appPreferencesProvider).setTourResumeStep(null);
}

/// Clears anything a nav branch has pushed on top of its root when the tour
/// is replayed. Call from each branch ROOT screen's `build`.
///
/// Branch navigator stacks survive tab switches and a replay, and
/// `goBranch(initialLocation: true)` only restores a branch's go_router
/// location — it cannot pop a route pushed imperatively with
/// `Navigator.push`. Any such screen left open (a match profile, a chat
/// thread, a benefit profile, a card's barcode page) therefore stays on top
/// of its branch, and the tour step that expects the branch root starts
/// against targets buried underneath it: the overlay lives in the app-level
/// `Overlay`, so it dims the wrong screen and anchors its tooltip to widgets
/// nobody can see — and a tap-gated step there can never be satisfied, which
/// is how the tour stalled. `isTargetRendered` does not catch this; it is a
/// registry lookup, and a covered route's targets are still mounted and
/// still registered.
///
/// Done at the branch root rather than on each pushed screen so it covers
/// every screen that branch can have pushed, including future ones.
void dismissPushedRoutesOnTourReplay(BuildContext context, WidgetRef ref) {
  ref.listen(tourGenerationProvider, (previous, next) {
    if (previous == next || !context.mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.popUntil((route) => route.isFirst);
  });
}

final matchTabTourShowcaseKey = GlobalKey();
final profileExplanationTourShowcaseKey = GlobalKey();
final viewProfileTapTourShowcaseKey = GlobalKey();
final scanTabTourShowcaseKey = GlobalKey();
final benefitsTabTourShowcaseKey = GlobalKey();

final profileTabTourShowcaseKey = GlobalKey();

/// Starts the cross-screen section after the Home tour finishes.
Future<void> maybeStartGuidedMatchingTour(ProviderContainer container) async {
  var hasCandidates = false;
  try {
    hasCandidates = (await container.read(
      matchCandidatesProvider.future,
    )).isNotEmpty;
  } catch (_) {
    // If matching cannot be demonstrated, continue with Scan instead.
  }

  if (!hasCandidates) {
    container.read(matchingTourStepProvider.notifier).state =
        MatchingTourStep.awaitingScanTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ShowcaseView.get().startShowCase([scanTabTourShowcaseKey]);
    });
    return;
  }

  // Straight to the Matches tab step. There used to be a separate
  // `awaitingMatchesIntro` step here, but no widget ever registered
  // `matchesIntroTourShowcaseKey`, so `startShowCase` ran against a target
  // that did not exist and the whole cross-screen tour died silently right
  // after the Home segment — leaving the user on Home with nothing
  // highlighted. The Matches nav step already introduces matching and is
  // tap-gated, so nothing is lost by going there directly.
  container.read(matchingTourStepProvider.notifier).state =
      MatchingTourStep.awaitingMatchTab;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ShowcaseView.get().startShowCase([matchTabTourShowcaseKey]);
  });
}

/// Continue to Scan after the report explanation, or immediately when the
/// report demo was already seen before the main tour reached the profile.
void continueTourToScan(ProviderContainer container) {
  container.read(matchingTourStepProvider.notifier).state =
      MatchingTourStep.awaitingScanTab;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ShowcaseView.get().startShowCase([scanTabTourShowcaseKey]);
  });
}

bool shouldShowReportAsMainTour(ProviderContainer container) {
  return container.read(matchingTourStepProvider) ==
          MatchingTourStep.awaitingReportDemo &&
      !container.read(hasSeenDemoProvider(DemoKey.reportUser));
}
