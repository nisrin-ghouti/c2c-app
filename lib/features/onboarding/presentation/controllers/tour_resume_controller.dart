import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../../../core/storage/shared_preferences_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../home_coach_mark_keys.dart';
import 'guided_matching_tour_controller.dart';

/// Nav-tab-level matching steps that need an explicit `startShowCase` call
/// on resume — every other [MatchingTourStep] is self-triggered by its own
/// destination screen once the provider value + route match (same as it
/// already is on a fresh run), so resuming those just means navigating and
/// setting the provider state.
final Map<MatchingTourStep, GlobalKey> _navTabResumeKeys = {
  MatchingTourStep.awaitingMatchTab: matchTabTourShowcaseKey,
  MatchingTourStep.awaitingScanTab: scanTabTourShowcaseKey,
  MatchingTourStep.awaitingBenefitsTab: benefitsTabTourShowcaseKey,
  MatchingTourStep.awaitingProfileTab: profileTabTourShowcaseKey,
};

const Map<MatchingTourStep, String> _routeForMatchingStep = {
  MatchingTourStep.awaitingMatchTab: AppRoutes.home,
  MatchingTourStep.awaitingCompatibilityDemo: AppRoutes.matches,
  MatchingTourStep.awaitingViewProfileTap: AppRoutes.matches,
  MatchingTourStep.awaitingScanTab: AppRoutes.home,
  MatchingTourStep.awaitingScanContent: AppRoutes.connect,
  MatchingTourStep.awaitingBenefitsTab: AppRoutes.home,
  MatchingTourStep.awaitingBenefitsContent: AppRoutes.benefits,
  MatchingTourStep.awaitingWalletTap: AppRoutes.benefits,
  MatchingTourStep.awaitingWalletContent: AppRoutes.benefits,
  MatchingTourStep.awaitingProfileTab: AppRoutes.home,
};

/// Attempts to resume the step-by-step tour from a persisted
/// `AppPreferences.tourResumeStep` id after a fresh app load (e.g. a page
/// refresh mid-tour). No-ops if nothing is persisted, the user never signs
/// in, or the resume target never mounts within a short bounded window —
/// in every "give up" case, the persisted step is cleared rather than
/// risking a stuck resume attempt on a later cold start.
///
/// [router] is passed in explicitly (rather than resolved via
/// `GoRouter.of(context)`) because [context] here is `C2CApp`'s own
/// context, which sits *above* `MaterialApp.router` in the tree — the
/// `GoRouter` InheritedWidget it provides isn't reachable from an ancestor
/// context, so `GoRouter.of(context)` throws.
Future<void> attemptTourResume(BuildContext context, GoRouter router) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final prefs = container.read(appPreferencesProvider);
  final resumeStep = prefs.tourResumeStep;
  if (resumeStep == null) return;

  var userId = container.read(authSessionProvider).valueOrNull?.userId;
  for (var i = 0; i < 15 && userId == null; i++) {
    await Future.delayed(const Duration(milliseconds: 200));
    userId = container.read(authSessionProvider).valueOrNull?.userId;
  }
  if (userId == null) {
    await prefs.setTourResumeStep(null);
    return;
  }

  if (resumeStep.startsWith('home.')) {
    await _resumeHomeStep(resumeStep.substring('home.'.length), prefs, router);
    return;
  }
  if (!resumeStep.startsWith('matching.')) return;

  var stepName = resumeStep.substring('matching.'.length);
  // The report-demo step depends on a pushed, non-URL-addressable screen
  // (MatchProfileScreen with an in-memory candidate) that can't survive a
  // cold reload — resume one step earlier instead, where the user re-taps
  // "View Profile" and the report-demo step re-triggers itself normally.
  if (stepName == MatchingTourStep.awaitingReportDemo.name) {
    stepName = MatchingTourStep.awaitingViewProfileTap.name;
  }

  MatchingTourStep step;
  try {
    step = MatchingTourStep.values.byName(stepName);
  } catch (_) {
    await prefs.setTourResumeStep(null);
    return;
  }
  if (step == MatchingTourStep.none) return;

  if (step == MatchingTourStep.awaitingMatchesIntro) {
    router.go(AppRoutes.matches);
    await Future.delayed(const Duration(milliseconds: 300));
    await maybeStartGuidedMatchingTour(container);
    return;
  }

  final route = _routeForMatchingStep[step];
  if (route == null) return;
  router.go(route);
  container.read(matchingTourStepProvider.notifier).state = step;

  final navKey = _navTabResumeKeys[step];
  if (navKey == null) {
    return; // Content step — the destination screen self-triggers.
  }

  for (var i = 0; i < 15; i++) {
    await Future.delayed(const Duration(milliseconds: 200));
    if (ShowcaseView.get().isTargetRendered(navKey)) {
      ShowcaseView.get().startShowCase([navKey]);
      return;
    }
  }
  await prefs.setTourResumeStep(null);
}

Future<void> _resumeHomeStep(
  String subId,
  AppPreferences prefs,
  GoRouter router,
) async {
  final index = homeTourStepOrder.indexWhere((e) => e.key == subId);
  if (index == -1) {
    await prefs.setTourResumeStep(null);
    return;
  }
  router.go(AppRoutes.home);
  final targetKey = homeTourStepOrder[index].value;
  for (var i = 0; i < 15; i++) {
    await Future.delayed(const Duration(milliseconds: 200));
    if (ShowcaseView.get().isTargetRendered(targetKey)) {
      ShowcaseView.get().startShowCase(
        homeTourStepOrder.sublist(index).map((e) => e.value).toList(),
      );
      return;
    }
  }
  await prefs.setTourResumeStep(null);
}
