import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/utils/initials.dart';
import '../../../../core/widgets/app_header_bar.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../events/domain/entities/campus_event.dart';
import '../../../onboarding/domain/entities/demo_key.dart';
import '../../../onboarding/presentation/controllers/demo_flags_controller.dart';
import '../../../onboarding/presentation/controllers/guided_matching_tour_controller.dart';
import '../../../onboarding/presentation/controllers/home_coach_mark_controller.dart';
import '../../../onboarding/presentation/home_coach_mark_keys.dart';
import '../../../onboarding/presentation/widgets/contextual_showcase.dart';
import '../../../onboarding/presentation/widgets/tour_intro_overlay.dart';
import '../../../points/presentation/providers/scanning_tab_provider.dart';
import '../../../events/presentation/providers/events_providers.dart';
import '../../../points/domain/entities/champions_announcement.dart';
import '../../../points/presentation/providers/points_providers.dart';
import '../../../points/presentation/widgets/month_announcement_dialog.dart';
import '../../../points/presentation/widgets/winner_bonus_dialog.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/home_dashboard.dart';
import '../controllers/home_controller.dart';
import '../widgets/home_stat_card.dart';
import '../widgets/points_badge.dart';

/// How far the stat-card row hangs below the hero card's bottom edge.
const double _statCardOverhang = 46;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _tourLaunchScheduled = false;

  Future<void> _showChampionsAnnouncements(
    BuildContext context,
    WidgetRef ref,
    ChampionsAnnouncement announcement,
  ) async {
    // Never interrupt a running showcase. These dialogs are triggered by an
    // async provider settling, so they can land in the middle of the first-run
    // tour, cover the spotlight and leave the sequence stranded. The
    // announcement stays unseen and shows next time Home is opened.
    if (ShowcaseView.get().isShowcaseRunning) return;

    // Winner popup first (personal, only for top 3), then the general one —
    // both "OK only", each marked seen individually so a re-render never
    // re-shows one the user already dismissed.
    if (announcement.hasUnseenWinner && announcement.amIWinner) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => WinnerBonusDialog(announcement: announcement),
      );
      if (!mounted) return;
      await ref.read(markChampionsAnnouncementSeenProvider)(
        general: false,
        winner: true,
      );
    }
    if (!context.mounted) return;
    if (announcement.hasUnseenGeneral) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => MonthAnnouncementDialog(announcement: announcement),
      );
      if (!mounted) return;
      await ref.read(markChampionsAnnouncementSeenProvider)(
        general: true,
        winner: false,
      );
    }
    if (!mounted) return;
    ref.invalidate(championsAnnouncementProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dashboardAsync = ref.watch(homeDashboardProvider);

    dismissPushedRoutesOnTourReplay(context, ref);

    ref.listen(championsAnnouncementProvider, (previous, next) {
      final announcement = next.valueOrNull;
      if (announcement != null && announcement.hasAnyUnseen) {
        _showChampionsAnnouncements(context, ref, announcement);
      }
    });

    // First-run step-by-step tour. Keep the Home "seen" flag false until
    // the Home sequence itself finishes so standalone contextual demos (most
    // importantly Accessibility) cannot race the intro or the main tour.
    final hasSeenHomeTour = ref.watch(hasSeenHomeCoachMarkProvider);
    if (hasSeenHomeTour) {
      _tourLaunchScheduled = false;
    } else if (!_tourLaunchScheduled) {
      _tourLaunchScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!context.mounted) return;
        final container = ProviderScope.containerOf(context, listen: false);

        final startTour = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => TourIntroOverlay(
            onNext: () => Navigator.of(dialogContext).pop(true),
            onClose: () => Navigator.of(dialogContext).pop(false),
          ),
        );

        if (!context.mounted) return;
        if (startTour != true) {
          closeMainTour(container);
          return;
        }

        final epoch = container.read(tourEpochProvider);
        late VoidCallback homeFinishListener;
        homeFinishListener = () {
          // Deferred: showcaseview invokes these with `for (final cb in
          // _onFinishCallbacks)`, and mutating that list inside a callback throws
          // ConcurrentModificationError on the next moveNext(), silently skipping
          // every callback after this one — including the tour's own listener.
          scheduleMicrotask(
            () => ShowcaseView.get().removeOnFinishCallback(homeFinishListener),
          );
          if (!mainTourStillCurrent(container, epoch)) return;
          container
              .read(demoFlagsControllerProvider)
              .markSeen(DemoKey.accessibility);
          container.read(homeCoachMarkControllerProvider.notifier).markSeen();
          maybeStartGuidedMatchingTour(container);
        };
        ShowcaseView.get().addOnFinishCallback(homeFinishListener);
        ShowcaseView.get().startShowCase([
          HomeCoachMarkKeys.navHome,
          // Back to back on purpose: the second step exists to draw the
          // contrast with the first.
          HomeCoachMarkKeys.homeEvents,
          HomeCoachMarkKeys.homeUpcomingEvents,
          ...HomeCoachMarkKeys.afterEventsTourOrder,
        ]);
      });
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeaderBar(title: l10n.navHome),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(homeDashboardProvider.future),
          child: dashboardAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => ListView(
              children: [
                const SizedBox(height: 120),
                Icon(
                  Icons.error_outline,
                  color: AppColors.destructive,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(l10n.homeLoadError, textAlign: TextAlign.center),
                ),
              ],
            ),
            data: (dashboard) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _Hero(dashboard: dashboard, l10n: l10n),
                  ),
                  // Reserves the space the stat cards hang into below the hero.
                  const SliverToBoxAdapter(
                    child: SizedBox(height: _statCardOverhang + 8),
                  ),
                  SliverToBoxAdapter(child: _SurveysSection(l10n: l10n)),
                  SliverToBoxAdapter(
                    child: TourShowcase(
                      showcaseKey: HomeCoachMarkKeys.homeEvents,
                      title: l10n.tourEventsNextMonthTitle,
                      description: l10n.tourEventsNextMonthDescription,
                      tooltipPosition: TooltipPosition.bottom,
                      child: _CampusEventsSection(l10n: l10n),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Hero extends ConsumerWidget {
  const _Hero({required this.dashboard, required this.l10n});

  final HomeDashboard dashboard;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).valueOrNull;

    // The stat cards sit in a Stack so they can hang below the gradient card's
    // bottom edge (half on the card, half on the page background).
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          // Extra bottom padding leaves room for the portion of the (fairly
          // tall, two-line-label) stat cards that overlaps the hero, so the
          // champions button clears them. Must be >= cardHeight - overhang.
          padding: EdgeInsets.fromLTRB(16, 12, 16, _statCardOverhang + 58),
          decoration: const BoxDecoration(
            gradient: AppGradients.hero,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting, with the user's avatar directly beneath it.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dashboard.greetingName.isNotEmpty)
                          Text(
                            '👋 ${l10n.homeGreeting(dashboard.greetingName)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        const SizedBox(height: 10),
                        InitialsAvatar(
                          initials: initialsOf(
                            profile?.fullName.isNotEmpty == true
                                ? profile!.fullName
                                : dashboard.greetingName,
                          ),
                          hue: profile?.avatarHue ?? 220,
                          imageUrl: profile?.avatarUrl,
                          size: 48,
                        ),
                      ],
                    ),
                  ),
                  TourShowcase(
                    showcaseKey: HomeCoachMarkKeys.pointsBadge,
                    title: l10n.tourPointsTitle,
                    description: l10n.tourPointsDescription,
                    child: PointsBadge(points: dashboard.summary.points),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                l10n.homeHeroTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TourShowcase(
                  showcaseKey: HomeCoachMarkKeys.championsButton,
                  title: l10n.tourChampionsTitle,
                  description: l10n.tourChampionsDescription,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Force the Champions tab, then switch to the Scanning
                      // branch — so this always lands on Champions even if Scan
                      // was the last tab open there.
                      ref.read(scanningTabRequestProvider.notifier).state =
                          ScanningTab.champions;
                      context.go(AppRoutes.connect);
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    icon: const Text('🏆'),
                    label: Text(
                      l10n.homeMonthlyChampions,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Straddling stat-card row: hangs `_statCardOverhang` below the card.
        Positioned(
          left: 16,
          right: 16,
          bottom: -_statCardOverhang,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TourShowcase(
                    showcaseKey: HomeCoachMarkKeys.statMyEvents,
                    title: l10n.tourMyEventsTitle,
                    description: l10n.tourMyEventsDescription,
                    child: HomeStatCard(
                      icon: Icons.event_note_outlined,
                      iconColor: AppColors.foreground,
                      backgroundColor: AppColors.pink,
                      label: l10n.homeMyEventsCalendar,
                      onTap: () => context.push(AppRoutes.myEvents),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TourShowcase(
                    showcaseKey: HomeCoachMarkKeys.homeUpcomingEvents,
                    title: l10n.tourUpcomingEventsTitle,
                    description: l10n.tourUpcomingEventsDescription,
                    child: HomeStatCard(
                      icon: Icons.calendar_month_outlined,
                      iconColor: AppColors.secondaryForeground,
                      backgroundColor: AppColors.sky,
                      label: l10n.homeUpcomingEvents,
                      count: dashboard.summary.upcomingEventsCount,
                      onTap: () => context.push(AppRoutes.events),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A preview of the campus events happening within the next 30 days, shown
/// below the Surveys banner. Cards open the full Events tab, which owns
/// registration/management — this is just a glance.
///
/// Distinct from the "Upcoming Events" stat card higher up the page, which
/// counts every future event with no horizon. Both used to be titled
/// "Upcoming Events", which read as the same section twice.
class _CampusEventsSection extends ConsumerWidget {
  const _CampusEventsSection({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsNextThirtyDaysProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.homeEventsNextMonth,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
              TextButton(
                // The next-month variant of the Events list, not the whole
                // tab: "See All" of a section that shows only the coming
                // month has to stay inside that window.
                onPressed: () => context.push(AppRoutes.eventsNextMonth),
                child: Text(l10n.homeSeeAll),
              ),
            ],
          ),
          eventsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (events) {
              if (events.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    l10n.homeEmptyEventsNextMonth,
                    style: const TextStyle(color: AppColors.mutedForeground),
                  ),
                );
              }
              final preview = events.take(5).toList();
              return SizedBox(
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: preview.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => _EventPreviewCard(
                    event: preview[index],
                    onTap: () => context.push(AppRoutes.events),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Home's survey call-to-action — a single tappable banner, always visible
/// as a shortcut into the full Surveys screen, regardless of whether
/// anything's currently pending.
class _SurveysSection extends StatelessWidget {
  const _SurveysSection({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TourShowcase(
        showcaseKey: HomeCoachMarkKeys.surveysBanner,
        title: l10n.tourSurveysTitle,
        description: l10n.tourSurveysDescription,
        child: GestureDetector(
          onTap: () => context.push(AppRoutes.surveys),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.mint.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/logo/surveyicon.jpeg',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.homeSurveysBannerCta,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.foreground,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventPreviewCard extends StatelessWidget {
  const _EventPreviewCard({required this.event, required this.onTap});

  final CampusEvent event;
  final VoidCallback onTap;

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final start = event.startsAt.toLocal();
    final languageCode = Localizations.localeOf(context).languageCode;
    final title = event.localizedTitle(languageCode);
    final location = event.localizedLocation(languageCode);
    final dateLine =
        '${_two(start.day)}.${_two(start.month)}  ${_two(start.hour)}:${_two(start.minute)}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 90,
              child: (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                  ? Image.network(
                      event.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _EventImageFallback(),
                    )
                  : const _EventImageFallback(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _MetaLine(
                    icon: Icons.calendar_today_outlined,
                    text: dateLine,
                  ),
                  if (location != null && location.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    _MetaLine(icon: Icons.location_on_outlined, text: location),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventImageFallback extends StatelessWidget {
  const _EventImageFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: AppGradients.hero),
      child: Center(
        child: Icon(Icons.event, color: AppColors.foreground, size: 30),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.mutedForeground),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }
}
