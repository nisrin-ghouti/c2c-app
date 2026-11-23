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
  final _matchesPageShowcaseKey = GlobalKey();
  bool _matchesGuide = false;

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final candidatesAsync = ref.watch(matchCandidatesProvider);
    _filters ??= MatchFilters(allLabel: l10n.filterAll);

    // A match profile or chat thread left open here would otherwise sit on
    // top of this branch through a replay, burying the Matches step's
    // targets.
    dismissPushedRoutesOnTourReplay(context, ref);

    ref.listen(tabGuideRequestProvider, (previous, next) {
      if (next != TabGuideTarget.matches) return;
      ref.read(tabGuideRequestProvider.notifier).state = null;
      setState(() => _matchesGuide = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final candidates =
            ref.read(matchCandidatesProvider).valueOrNull ?? const [];
        final visible = _filters!.apply(candidates);
        final keys = visible.isEmpty
            ? [_matchesPageShowcaseKey]
            : [
                _compatibilityShowcaseKey,
                _chatShowcaseKey,
                profileExplanationTourShowcaseKey,
              ];
        if (!ShowcaseView.get().isTargetRendered(keys.first)) return;
        ShowcaseView.get().startShowCase(keys);
      });
    });

    return Scaffold(
      appBar: AppHeaderBar(
        title: l10n.matchesTitle,
        onOpenGuide: () => requestTabGuide(ref, TabGuideTarget.matches),
      ),
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
            final showMatchesGuide = _matchesGuide && filtered.isNotEmpty;

            // The one-time compatibility note stays, and it does not run
            // while the student has the tab guide open.
            final showMatchingDemo =
                filtered.isNotEmpty &&
                !compatibilityDemoSeen &&
                !showMatchesGuide;
            if (showMatchingDemo) {
              startContextualDemoOnce(
                context: context,
                ref: ref,
                key: DemoKey.matching,
                showcaseKeys: [_compatibilityShowcaseKey],
              );
            }

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TourShowcase(
                          showcaseKey: _matchesPageShowcaseKey,
                          title: l10n.tourMatchesIntroTitle,
                          description: l10n.tourMatchesIntroDescription,
                          hidePrevious: true,
                          child: AppSearchField(
                            controller: _searchController,
                            hintText: l10n.matchesSearchHint,
                            onChanged: (value) => setState(
                              () => _filters = _filters!.copyWith(
                                searchQuery: value,
                              ),
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
                              ? (child) => showMatchesGuide
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
                          messageButtonWrapper: index == 0 && showMatchesGuide
                              ? (child) => TourShowcase(
                                  showcaseKey: _chatShowcaseKey,
                                  title: l10n.tourChatTitle,
                                  description: l10n.tourChatDescription,
                                  child: child,
                                )
                              : null,
                          viewProfileButtonWrapper:
                              index == 0 && showMatchesGuide
                              ? (child) => TourShowcase(
                                  showcaseKey: profileExplanationTourShowcaseKey,
                                  title: l10n.tourStudentProfileTitle,
                                  description:
                                      l10n.tourStudentProfileDescription,
                                  child: child,
                                )
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
