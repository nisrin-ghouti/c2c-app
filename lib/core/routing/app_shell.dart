import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../features/benefits/presentation/providers/benefits_providers.dart';
import '../../features/events/presentation/providers/events_providers.dart';
import '../../features/onboarding/presentation/controllers/guided_matching_tour_controller.dart';
import '../../features/onboarding/presentation/home_coach_mark_keys.dart';
import '../../features/notifications/presentation/widgets/event_reminder_popup.dart';
import '../../features/onboarding/presentation/widgets/contextual_showcase.dart';
import '../accessibility/draggable_accessibility_button.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/app_bottom_nav.dart';

/// The 5-tab bottom navigation shell. Destinations are listed in *logical*
/// (reading-order) sequence — Home first, Profile last — so [AppBottomNav]'s
/// [Row] mirrors them correctly for RTL vs LTR locales without any manual
/// per-locale reordering (same trick used for the auth-screen tabs).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // Mounted here rather than on the events screen so it covers the whole
    // signed-in session: Home shows events too, and a student sitting on any
    // tab should still see an admin's edit land. Kept alive by this watch and
    // torn down with the shell.
    ref.watch(eventsLiveRefreshProvider);
    // Same reasoning for benefits: the Benefits tab is a nav branch that stays
    // mounted all session, so its autoDispose catalog never disposed and an
    // admin's edit was invisible until the app was killed.
    ref.watch(benefitsLiveRefreshProvider);
    // Being accepted onto a program is a write to a table no event-row change
    // accompanies, so it needs its own subscription to reach the open screen.
    ref.watch(programAcceptanceLiveRefreshProvider);

    return Scaffold(
      // The accessibility button lives in the body Stack rather than in
      // `floatingActionButton` so the user can drag it out of the way of
      // whatever it's covering. Keeping it inside the body also confines it to
      // the content area, so it can never sit on top of the nav bar below.
      body: Stack(
        children: [
          navigationShell,
          const Positioned.fill(child: DraggableAccessibilityButton()),
          // Zero-size sibling, not a wrapper: it owns the once-a-day reminder
          // dialog for whichever tab the user lands on, and keeping it beside
          // `navigationShell` rather than above it means its async rebuilds
          // never remount the screens — which was tearing down a running
          // first-run tour on Home.
          const EventReminderPopupHost(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onSelect: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        itemWrapper: (index, child) {
          var wrapped = child;

          // Keep the original coach-mark targets mounted. Home is also the
          // first step of the main tour; the other four legacy targets remain
          // available without being removed from the app.
          if (index < HomeCoachMarkKeys.navTabs.length) {
            final (title, description) = switch (index) {
              0 => (
                l10n.coachMarkNavHomeTitle,
                l10n.coachMarkNavHomeDescription,
              ),
              1 => (
                l10n.coachMarkNavMatchesTitle,
                l10n.coachMarkNavMatchesDescription,
              ),
              2 => (
                l10n.coachMarkNavScanTitle,
                l10n.coachMarkNavScanDescription,
              ),
              3 => (
                l10n.coachMarkNavBenefitsTitle,
                l10n.coachMarkNavBenefitsDescription,
              ),
              _ => (
                l10n.coachMarkNavProfileTitle,
                l10n.coachMarkNavProfileDescription,
              ),
            };
            wrapped = index == 0
                ? TourShowcase(
                    showcaseKey: HomeCoachMarkKeys.navHome,
                    title: title,
                    description: description,
                    hidePrevious: true,
                    child: wrapped,
                  )
                : Showcase(
                    key: HomeCoachMarkKeys.navTabs[index],
                    title: title,
                    description: description,
                    child: wrapped,
                  );
          }

          return _MainTourNavSpotlight(
            index: index,
            // initialLocation: true — always land on the branch's ROOT.
            //
            // Branch navigator stacks survive tab switches and a tour replay,
            // so a tab the user had drilled into (a match profile, a benefit)
            // is still on top of its stack. The tour's next step expects the
            // branch's root screen, and sending it anywhere else leaves the
            // step with no target.
            // initialLocation: true — always land on the branch's ROOT.
            // Branch navigator stacks survive tab switches and a replay, so a
            // tab the user drilled into during an earlier tour still has that
            // screen on top, and the next step would have no target there.
            onNavigate: () =>
                navigationShell.goBranch(index, initialLocation: true),
            child: wrapped,
          );
        },
        items: [
          AppBottomNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: l10n.navHome,
          ),
          AppBottomNavItem(
            icon: Icons.people_outline,
            selectedIcon: Icons.people,
            label: l10n.navMatches,
          ),
          AppBottomNavItem(
            icon: Icons.qr_code_scanner_outlined,
            selectedIcon: Icons.qr_code_scanner,
            label: l10n.navScanning,
          ),
          AppBottomNavItem(
            icon: Icons.card_giftcard_outlined,
            selectedIcon: Icons.card_giftcard,
            label: l10n.navBenefits,
          ),
          AppBottomNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}

/// Tap-gated navigation step for the cross-screen main tour. Only the
/// highlighted tab is interactive while the overlay is visible.
class _MainTourNavSpotlight extends ConsumerWidget {
  const _MainTourNavSpotlight({
    required this.index,
    required this.onNavigate,
    required this.child,
  });

  final int index;
  final VoidCallback onNavigate;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(matchingTourStepProvider);
    final l10n = AppLocalizations.of(context);

    final config = switch ((index, step)) {
      (1, MatchingTourStep.awaitingMatchTab) => (
        key: matchTabTourShowcaseKey,
        title: l10n.tourMatchesNavTitle,
        description: l10n.tourMatchesNavDescription,
        next: MatchingTourStep.awaitingCompatibilityDemo,
      ),
      (2, MatchingTourStep.awaitingScanTab) => (
        key: scanTabTourShowcaseKey,
        title: l10n.tourScanNavTitle,
        description: l10n.tourTapToContinue,
        next: MatchingTourStep.awaitingScanContent,
      ),
      (3, MatchingTourStep.awaitingBenefitsTab) => (
        key: benefitsTabTourShowcaseKey,
        title: l10n.tourBenefitsNavTitle,
        description: l10n.tourTapToContinue,
        next: MatchingTourStep.awaitingBenefitsContent,
      ),
      _ => null,
    };

    if (index == 4 && step == MatchingTourStep.awaitingProfileTab) {
      return TourShowcase(
        showcaseKey: profileTabTourShowcaseKey,
        title: l10n.tourProfileTitle,
        description: l10n.tourProfileDescription,
        child: child,
      );
    }

    if (config == null) return child;

    return GuidedTapShowcase(
      showcaseKey: config.key,
      title: config.title,
      description: config.description,
      onTap: () {
        ref.read(matchingTourStepProvider.notifier).state = config.next;
        onNavigate();
      },
      child: child,
    );
  }
}
