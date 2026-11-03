import 'package:flutter/widgets.dart';

/// Shared GlobalKeys for the first-run step-by-step tour.
abstract final class HomeCoachMarkKeys {
  static final navHome = GlobalKey();
  static final navMatches = GlobalKey();
  static final navScan = GlobalKey();
  static final navBenefits = GlobalKey();
  static final navProfile = GlobalKey();

  /// The "Events in the Next Month" list below the Surveys banner.
  ///
  /// This and [homeUpcomingEvents] used to share one key, so both highlighted
  /// at once as a single step with one tooltip. They answer different
  /// questions — "what's on soon" vs "what can I sign up for at all" — and a
  /// combined highlight gave the user no way to tell which explanation
  /// belonged to which, so they are now consecutive steps with their own copy.
  static final homeEvents = GlobalKey();

  /// The blue "Upcoming Events" stat card in the hero. Explained immediately
  /// after [homeEvents] so the contrast between the two lands while the first
  /// is still fresh.
  static final homeUpcomingEvents = GlobalKey();
  static final statMyEvents = GlobalKey();
  static final pointsBadge = GlobalKey();
  static final championsButton = GlobalKey();
  static final surveysBanner = GlobalKey();
  static final accessibilityButton = GlobalKey();

  static final List<GlobalKey> navTabs = [
    navHome,
    navMatches,
    navScan,
    navBenefits,
    navProfile,
  ];

  /// Home steps that remain after the two events explanations.
  static final List<GlobalKey> afterEventsTourOrder = [
    statMyEvents,
    pointsBadge,
    championsButton,
    surveysBanner,
    accessibilityButton,
  ];
}

/// Ordered (id, key) pairs matching the exact single `startShowCase` list
/// `home_screen.dart` runs for the whole Home tour segment — used only to
/// persist/resume "which Home step was last active" (`TourResumeController`),
/// not for any reactive UI gating (Home's sequence is already just one flat
/// native showcaseview list).
final List<MapEntry<String, GlobalKey>> homeTourStepOrder = [
  MapEntry('navHome', HomeCoachMarkKeys.navHome),
  MapEntry('homeEvents', HomeCoachMarkKeys.homeEvents),
  MapEntry('homeUpcomingEvents', HomeCoachMarkKeys.homeUpcomingEvents),
  MapEntry('statMyEvents', HomeCoachMarkKeys.statMyEvents),
  MapEntry('pointsBadge', HomeCoachMarkKeys.pointsBadge),
  MapEntry('championsButton', HomeCoachMarkKeys.championsButton),
  MapEntry('surveysBanner', HomeCoachMarkKeys.surveysBanner),
  MapEntry('accessibilityButton', HomeCoachMarkKeys.accessibilityButton),
];
