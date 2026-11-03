import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../admin/domain/entities/option_list_type.dart';
import '../../../admin/presentation/providers/option_label_providers.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/initials_avatar.dart';
import '../../../auth/domain/entities/gender.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../chat/presentation/screens/chat_thread_screen.dart';
import '../../../chat/presentation/widgets/report_user_sheet.dart';
import '../../../onboarding/domain/entities/demo_key.dart';
import '../../../onboarding/presentation/controllers/demo_flags_controller.dart';
import '../../../onboarding/presentation/controllers/guided_matching_tour_controller.dart';
import '../../../onboarding/presentation/widgets/contextual_showcase.dart';
import '../../domain/entities/match_candidate.dart';

class MatchProfileScreen extends ConsumerStatefulWidget {
  const MatchProfileScreen({super.key, required this.candidate});

  final MatchCandidate candidate;

  @override
  ConsumerState<MatchProfileScreen> createState() => _MatchProfileScreenState();
}

class _MatchProfileScreenState extends ConsumerState<MatchProfileScreen> {
  final _reportButtonShowcaseKey = GlobalKey();
  bool _mainReportTourKicked = false;

  MatchCandidate get candidate => widget.candidate;

  Future<void> _openChat(BuildContext context, WidgetRef ref) async {
    final chatId = await ref.read(getOrCreateChatProvider)(candidate.id);
    if (!context.mounted) return;
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

  /// Completes once this route's push animation has settled (or immediately
  /// if there is no animation in flight). Showcase targets measured while the
  /// page is still sliding resolve to off-screen coordinates.
  Future<void> _waitForRouteTransition() {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null ||
        animation.status == AnimationStatus.completed ||
        animation.status == AnimationStatus.dismissed) {
      return Future<void>.value();
    }

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
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final mainReportTour =
        ref.watch(matchingTourStepProvider) ==
        MatchingTourStep.awaitingReportDemo;
    final reportSeen = ref.watch(hasSeenDemoProvider(DemoKey.reportUser));

    if (mainReportTour && !_mainReportTourKicked) {
      _mainReportTourKicked = true;
      ref.read(demoFlagsControllerProvider).markSeen(DemoKey.reportUser);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        // Resolved before the await so no BuildContext crosses it.
        final container = ProviderScope.containerOf(context, listen: false);

        // The tour reaches this step as this route is being pushed, so the
        // first frame lands mid-slide. showcaseview measures its target when
        // the showcase starts and never re-measures once the transition
        // settles, so starting here caches an off-screen position: the report
        // button is the app bar's trailing action, and mid-slide its leading
        // edge sits past the screen width. `TargetPositionService.getRect`
        // clamps the far edge to that width but not the near one, so the rect
        // inverts, reads as empty, and the highlight is silently dropped
        // while the overlay still paints.
        //
        // The timeout keeps this bounded: a tour step must never hang waiting
        // on an animation that fails to report completion. Worst case we
        // measure early and lose one highlight, never the rest of the tour.
        await _waitForRouteTransition().timeout(
          const Duration(milliseconds: 800),
          onTimeout: () {},
        );
        if (!mounted) return;
        final epoch = container.read(tourEpochProvider);
        if (!mainTourStillCurrent(container, epoch)) return;
        late VoidCallback finishListener;
        finishListener = () {
          // Deferred: showcaseview invokes these with `for (final cb in
          // _onFinishCallbacks)`, and mutating that list inside a callback throws
          // ConcurrentModificationError on the next moveNext(), silently skipping
          // every callback after this one — including the tour's own listener.
          scheduleMicrotask(
            () => ShowcaseView.get().removeOnFinishCallback(finishListener),
          );
          if (!mainTourStillCurrent(container, epoch)) return;
          continueTourToScan(container);
        };
        ShowcaseView.get().addOnFinishCallback(finishListener);
        ShowcaseView.get().startShowCase([_reportButtonShowcaseKey]);
      });
    } else if (!mainReportTour && !reportSeen) {
      startContextualDemoOnce(
        context: context,
        ref: ref,
        key: DemoKey.reportUser,
        showcaseKeys: [_reportButtonShowcaseKey],
      );
    }

    final subtitleParts = [
      if (candidate.fieldsOfStudy.isNotEmpty)
        localizedOptionLabel(
          ref,
          context,
          type: OptionListType.fieldOfStudy,
          storedLabel: candidate.fieldsOfStudy.first,
        ),
      if (candidate.degree != null && candidate.degree!.isNotEmpty)
        localizedOptionLabel(
          ref,
          context,
          type: OptionListType.degree,
          storedLabel: candidate.degree,
        ),
      if (candidate.year != null) '${l10n.profileYearLabel} ${candidate.year}',
    ];

    final studiesRows = <Widget>[
      if (candidate.gender != null)
        _InfoRow(
          label: l10n.profileGenderLabel,
          value: switch (candidate.gender!) {
            Gender.male => l10n.genderMale,
            Gender.female => l10n.genderFemale,
            Gender.undisclosed => l10n.genderUndisclosed,
          },
        ),
      if (candidate.fieldsOfStudy.isNotEmpty)
        _InfoRow(
          label: l10n.profileFieldOfStudyLabel,
          value: localizedOptionLabels(
            ref,
            context,
            type: OptionListType.fieldOfStudy,
            storedLabels: candidate.fieldsOfStudy,
          ),
        ),
      if (candidate.faculties.isNotEmpty)
        _InfoRow(
          label: l10n.profileFacultyLabel,
          value: localizedOptionLabels(
            ref,
            context,
            type: OptionListType.faculty,
            storedLabels: candidate.faculties,
          ),
        ),
      if (candidate.degree != null && candidate.degree!.isNotEmpty)
        _InfoRow(
          label: l10n.profileDegreeLabel,
          value: localizedOptionLabel(
            ref,
            context,
            type: OptionListType.degree,
            storedLabel: candidate.degree,
          ),
        ),
      if (candidate.year != null)
        _InfoRow(label: l10n.profileYearLabel, value: '${candidate.year}'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(candidate.fullName.isEmpty ? '—' : candidate.fullName),
        actions: [
          mainReportTour
              ? TourShowcase(
                  showcaseKey: _reportButtonShowcaseKey,
                  title: l10n.tourReportTitle,
                  description: l10n.tourReportDescription,
                  hidePrevious: true,
                  child: IconButton(
                    icon: const Icon(Icons.flag_outlined),
                    tooltip: l10n.reportUserAction,
                    onPressed: () => showReportUserSheet(
                      context,
                      candidate.id,
                      candidate.fullName,
                    ),
                  ),
                )
              : ContextualShowcase(
                  showcaseKey: _reportButtonShowcaseKey,
                  title: l10n.demoReportUserTitle,
                  description: l10n.demoReportUserMessage,
                  child: IconButton(
                    icon: const Icon(Icons.flag_outlined),
                    tooltip: l10n.reportUserAction,
                    onPressed: () => showReportUserSheet(
                      context,
                      candidate.id,
                      candidate.fullName,
                    ),
                  ),
                ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: InitialsAvatar(
                initials: candidate.initials,
                hue: candidate.avatarHue,
                imageUrl: candidate.avatarUrl,
                size: 96,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                candidate.fullName.isEmpty ? '—' : candidate.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
            if (subtitleParts.isNotEmpty) ...[
              const SizedBox(height: 4),
              Center(
                child: Text(
                  subtitleParts.join(' • '),
                  style: const TextStyle(color: AppColors.mutedForeground),
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _openChat(context, ref),
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(l10n.profileMessageAction),
            ),
            if (candidate.bio != null && candidate.bio!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _Section(
                title: l10n.profileAboutLabel,
                icon: Icons.person_outline,
                child: Text(candidate.bio!),
              ),
            ],
            if (studiesRows.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Section(
                title: l10n.profileStudiesTitle,
                icon: Icons.school_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: studiesRows,
                ),
              ),
            ],
            if (candidate.interests.isNotEmpty ||
                candidate.hobbies.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Section(
                title: l10n.profileInterestsLabel,
                icon: Icons.favorite_border,
                child: _TagWrap(
                  tags: {...candidate.interests, ...candidate.hobbies}.map((v) {
                    final fromInterest = localizedOptionLabel(
                      ref,
                      context,
                      type: OptionListType.interest,
                      storedLabel: v,
                    );
                    return fromInterest != v
                        ? fromInterest
                        : localizedOptionLabel(
                            ref,
                            context,
                            type: OptionListType.hobby,
                            storedLabel: v,
                          );
                  }).toList(),
                ),
              ),
            ],
            if (candidate.languages.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Section(
                title: l10n.profileLanguagesLabel,
                icon: Icons.translate,
                child: _TagWrap(
                  tags: candidate.languages
                      .map(
                        (v) => localizedOptionLabel(
                          ref,
                          context,
                          type: OptionListType.language,
                          storedLabel: v,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A titled, bordered card section — matches the card style used on the user's
/// own profile tab, so the student profile reads as part of the same app.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagWrap extends StatelessWidget {
  const _TagWrap({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tag in tags)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.mint.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(tag, style: const TextStyle(fontSize: 12)),
          ),
      ],
    );
  }
}
