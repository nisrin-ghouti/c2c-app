import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_header_bar.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../chat/presentation/screens/chat_thread_screen.dart';
import '../../../onboarding/domain/entities/demo_key.dart';
import '../../../onboarding/presentation/controllers/demo_flags_controller.dart';
import '../../../onboarding/presentation/controllers/guided_matching_tour_controller.dart';
import '../../../onboarding/presentation/widgets/contextual_showcase.dart';
import '../../domain/entities/match_candidate.dart';
import '../controllers/matches_controller.dart';
import '../widgets/match_candidate_card.dart';
import '../widgets/match_filters.dart';
import '../widgets/match_filters_panel.dart';
import 'match_profile_screen.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  bool _filtersExpanded = false;
  MatchFilters? _filters;
  final _searchController = TextEditingController();

  /// Highest-compatibility-first by default, matching the previous fixed
  /// sort order.
  bool _sortAscending = false;

  final _compatibilityShowcaseKey = GlobalKey();
  final _chatShowcaseKey = GlobalKey();
  bool _mainMatchTourSequenceKicked = false;
  bool _viewProfileTourSequenceKicked = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openChat(MatchCandidate candidate) async {
    final chatId = await ref.read(getOrCreateChatProvider)(candidate.id);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatThreadScreen(
          chatId: chatId,
          otherUserId: candidate.id,
          otherFullName: candidate.fullName,
          otherAvatarHue: candidate.avatarHue,
          otherAvatarUrl: candidate.avatarUrl,
        ),
      ),
    );
  }

  /// Completes once this route's animation has settled, bounded so a tour
  /// step can never hang waiting on one that fails to report completion.
  Future<void> _waitForNavigationToSettle() async {
    final animation = ModalRoute.of(context)?.animation;
    if (animation != null &&
        animation.status != AnimationStatus.completed &&
        animation.status != AnimationStatus.dismissed) {
      final completer = Completer<void>();
      void listener(AnimationStatus status) {
        if (status != AnimationStatus.completed &&
            status != AnimationStatus.dismissed) {
          return;
        }
        animation.removeStatusListener(listener);
        if (!completer.isCompleted) completer.complete();
      }

      animation.addStatusListener(listener);
      await completer.future.timeout(
        const Duration(milliseconds: 800),
        onTimeout: () {},
      );
    }
    // A branch pop is not this route's own animation, so also give the
    // framework a frame to finish laying the list out before measuring.
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final candidatesAsync = ref.watch(matchCandidatesProvider);
    _filters ??= MatchFilters(allLabel: l10n.filterAll);

    // A match profile or chat thread left open here would otherwise sit on
    // top of this branch through a replay, burying the Matches step's
    // targets.
    dismissPushedRoutesOnTourReplay(context, ref);

    return Scaffold(
      appBar: AppHeaderBar(title: l10n.matchesTitle),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(matchCandidatesProvider.future),
        child: candidatesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ListView(
            children: [
              const SizedBox(height: 120),
              Center(child: Text(l10n.matchesLoadError)),
            ],
          ),
          data: (candidates) {
            final filtered = _filters!.apply(candidates)
              ..sort(
                (a, b) => _sortAscending
                    ? a.compatibilityPercent.compareTo(b.compatibilityPercent)
                    : b.compatibilityPercent.compareTo(a.compatibilityPercent),
              );

            final compatibilityDemoSeen = ref.watch(
              hasSeenDemoProvider(DemoKey.matching),
            );
            final tourStep = ref.watch(matchingTourStepProvider);
            final mainMatchTour =
                filtered.isNotEmpty &&
                tourStep == MatchingTourStep.awaitingCompatibilityDemo;
            // Reset once this step passes, so replaying the tour runs it
            // again. The shell is a StatefulShellRoute.indexedStack, so this
            // State outlives a replay and a one-shot flag would stay true —
            // silently skipping the step and stalling the tour. Matches
            // `scan_card.dart`, which already does this.
            if (!mainMatchTour) _mainMatchTourSequenceKicked = false;

            // Outside the main first-run tour, preserve the original
            // one-time contextual compatibility explanation unchanged.
            final showMatchingDemo =
                filtered.isNotEmpty && !compatibilityDemoSeen && !mainMatchTour;
            if (showMatchingDemo) {
              startContextualDemoOnce(
                context: context,
                ref: ref,
                key: DemoKey.matching,
                showcaseKeys: [_compatibilityShowcaseKey],
              );
            }

            // During the main tour, explain compatibility, Chat and Profile
            // with the standard Previous/Next controls. After that sequence,
            // require a real tap on the Profile button before continuing.
            if (mainMatchTour && !_mainMatchTourSequenceKicked) {
              _mainMatchTourSequenceKicked = true;
              ref.read(demoFlagsControllerProvider).markSeen(DemoKey.matching);
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!mounted) return;
                // Wait for navigation to settle before starting.
                //
                // The tour taps the Matches tab, and `goBranch(initialLocation:
                // true)` pops whatever screen an earlier tour left on this
                // branch — an animation. showcaseview measures its target once,
                // when the showcase starts, and never re-measures, so starting
                // mid-pop caches a moving position and the step becomes
                // unusable: the overlay paints but its tooltip cannot be
                // reached, which reads as the tour freezing. Same failure mode
                // as the report-user step on a pushed route.
                await _waitForNavigationToSettle();
                if (!mounted) return;
                if (ref.read(matchingTourStepProvider) !=
                    MatchingTourStep.awaitingCompatibilityDemo) {
                  return;
                }
                final epoch = ref.read(tourEpochProvider);
                late VoidCallback finishListener;
                finishListener = () {
                  // Deferred: showcaseview invokes these with `for (final cb in
                  // _onFinishCallbacks)`, and mutating that list inside a callback throws
                  // ConcurrentModificationError on the next moveNext(), silently skipping
                  // every callback after this one — including the tour's own listener.
                  scheduleMicrotask(
                    () => ShowcaseView.get().removeOnFinishCallback(
                      finishListener,
                    ),
                  );
                  if (!mounted) return;
                  if (ref.read(tourEpochProvider) != epoch) return;
                  ref.read(matchingTourStepProvider.notifier).state =
                      MatchingTourStep.awaitingViewProfileTap;
                };
                ShowcaseView.get().addOnFinishCallback(finishListener);
                ShowcaseView.get().startShowCase([
                  _compatibilityShowcaseKey,
                  _chatShowcaseKey,
                  profileExplanationTourShowcaseKey,
                ]);
              });
            }

            final showViewProfileTourStep =
                filtered.isNotEmpty &&
                tourStep == MatchingTourStep.awaitingViewProfileTap;
            if (!showViewProfileTourStep) {
              _viewProfileTourSequenceKicked = false;
            }
            if (showViewProfileTourStep && !_viewProfileTourSequenceKicked) {
              _viewProfileTourSequenceKicked = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || ShowcaseView.get().isShowcaseRunning) return;
                if (ref.read(matchingTourStepProvider) !=
                    MatchingTourStep.awaitingViewProfileTap) {
                  return;
                }
                ShowcaseView.get().startShowCase([
                  viewProfileTapTourShowcaseKey,
                ]);
              });
            }

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppSearchField(
                          controller: _searchController,
                          hintText: l10n.matchesSearchHint,
                          onChanged: (value) => setState(
                            () => _filters = _filters!.copyWith(
                              searchQuery: value,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Spacer(),
                            Tooltip(
                              message: _sortAscending
                                  ? l10n.matchesSortLowToHigh
                                  : l10n.matchesSortHighToLow,
                              child: TextButton.icon(
                                onPressed: () => setState(
                                  () => _sortAscending = !_sortAscending,
                                ),
                                icon: Icon(
                                  _sortAscending
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  size: 18,
                                ),
                                label: Text(l10n.matchesSortToggle),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => setState(
                                () => _filtersExpanded = !_filtersExpanded,
                              ),
                              icon: Icon(
                                _filtersExpanded
                                    ? Icons.expand_less
                                    : Icons.tune,
                                size: 18,
                              ),
                              label: Text(l10n.matchesFilterToggle),
                            ),
                          ],
                        ),
                        if (_filtersExpanded) ...[
                          const SizedBox(height: 4),
                          MatchFiltersPanel(
                            candidates: candidates,
                            filters: _filters!,
                            onChanged: (next) =>
                                setState(() => _filters = next),
                            onApply: () =>
                                setState(() => _filtersExpanded = false),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          l10n.matchesResultsCount(filtered.length),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          l10n.matchesEmpty,
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final candidate = filtered[index];
                        return MatchCandidateCard(
                          candidate: candidate,
                          onViewProfile: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  MatchProfileScreen(candidate: candidate),
                            ),
                          ),
                          onMessage: () => _openChat(candidate),
                          compatibilityBadgeWrapper: index == 0
                              ? (child) => mainMatchTour
                                    ? TourShowcase(
                                        showcaseKey: _compatibilityShowcaseKey,
                                        title: l10n.tourCompatibilityTitle,
                                        description:
                                            l10n.tourCompatibilityDescription,
                                        hidePrevious: true,
                                        child: child,
                                      )
                                    : showMatchingDemo
                                    ? ContextualShowcase(
                                        showcaseKey: _compatibilityShowcaseKey,
                                        title: l10n.demoMatchingTitle,
                                        description: l10n.demoMatchingMessage,
                                        child: child,
                                      )
                                    : child
                              : null,
                          messageButtonWrapper: index == 0 && mainMatchTour
                              ? (child) => TourShowcase(
                                  showcaseKey: _chatShowcaseKey,
                                  title: l10n.tourChatTitle,
                                  description: l10n.tourChatDescription,
                                  child: child,
                                )
                              : null,
                          viewProfileButtonWrapper: index == 0
                              ? (child) {
                                  if (mainMatchTour) {
                                    return TourShowcase(
                                      showcaseKey:
                                          profileExplanationTourShowcaseKey,
                                      title: l10n.tourStudentProfileTitle,
                                      description:
                                          l10n.tourStudentProfileDescription,
                                      child: child,
                                    );
                                  }
                                  if (showViewProfileTourStep) {
                                    return GuidedTapShowcase(
                                      showcaseKey:
                                          viewProfileTapTourShowcaseKey,
                                      title: l10n.tourStudentProfileTitle,
                                      description: l10n.tourTapToContinue,
                                      onTap: () {
                                        ref
                                            .read(
                                              matchingTourStepProvider.notifier,
                                            )
                                            .state = MatchingTourStep
                                            .awaitingReportDemo;
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => MatchProfileScreen(
                                              candidate: candidate,
                                            ),
                                          ),
                                        );
                                      },
                                      child: child,
                                    );
                                  }
                                  return child;
                                }
                              : null,
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
