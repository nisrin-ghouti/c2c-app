import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../../domain/entities/survey.dart';
import '../providers/surveys_providers.dart';
import 'survey_take_screen.dart';

class SurveysListScreen extends ConsumerStatefulWidget {
  const SurveysListScreen({super.key});

  @override
  ConsumerState<SurveysListScreen> createState() => _SurveysListScreenState();
}

class _SurveysListScreenState extends ConsumerState<SurveysListScreen> {
  SurveyState _filter = SurveyState.pending;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final surveysAsync = ref.watch(availableSurveysProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.surveysTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.foreground,
          ),
        ),
      ),
      body: SafeArea(
        child: surveysAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(l10n.surveysLoadError)),
          data: (surveys) {
            final active = surveys
                .where((s) => s.state == SurveyState.pending)
                .length;
            final completed = surveys
                .where((s) => s.state == SurveyState.completed)
                .length;
            final filtered = surveys.where((s) => s.state == _filter).toList();
            final isActiveTab = _filter == SurveyState.pending;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: SegmentedToggle<SurveyState>(
                    selectedColor: AppColors.primaryStrong,
                    options: [
                      SegmentOption(
                        value: SurveyState.pending,
                        label: l10n.surveysTabActive,
                        icon: Icons.assignment_outlined,
                      ),
                      SegmentOption(
                        value: SurveyState.completed,
                        label: l10n.surveysTabCompleted,
                        icon: Icons.check_circle_outline,
                      ),
                    ],
                    value: _filter,
                    onChanged: (value) => setState(() => _filter = value),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        isActiveTab
                            ? l10n.surveysTabActive
                            : l10n.surveysTabCompleted,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.foreground,
                        ),
                      ),
                      const Spacer(),
                      _CountBadge(count: isActiveTab ? active : completed),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            isActiveTab
                                ? l10n.surveysEmptyPending
                                : l10n.surveysEmptyCompleted,
                            style: const TextStyle(
                              color: AppColors.mutedForeground,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) => _SurveyCard(
                            survey: filtered[index],
                            l10n: l10n,
                            enabled: isActiveTab,
                          ),
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

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 24),
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primaryStrong,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Category-style presentation for a survey card's icon tile — cycles
/// through a small pastel palette by the survey's id so different surveys
/// read as visually distinct categories, without the survey model needing
/// an actual category field (it doesn't have one).
class _SurveyPresentation {
  const _SurveyPresentation(this.background, this.foreground, this.icon);

  final Color background;
  final Color foreground;
  final IconData icon;
}

const _surveyPresentations = [
  _SurveyPresentation(
    AppColors.mint,
    AppColors.success,
    Icons.chat_bubble_outline,
  ),
  _SurveyPresentation(
    AppColors.sky,
    AppColors.secondaryForeground,
    Icons.event_outlined,
  ),
  _SurveyPresentation(
    AppColors.primaryGlow,
    AppColors.primaryStrong,
    Icons.campaign_outlined,
  ),
  _SurveyPresentation(
    AppColors.peach,
    AppColors.destructive,
    Icons.bug_report_outlined,
  ),
];

_SurveyPresentation _presentationFor(String surveyId) {
  return _surveyPresentations[surveyId.hashCode.abs() %
      _surveyPresentations.length];
}

/// Matches `champions_podium.dart`'s "gold" reward accent — reused here
/// (rather than inventing a new color) for the points star.
const _pointsStarColor = Color(0xFFF5A623);

class _SurveyCard extends StatelessWidget {
  const _SurveyCard({
    required this.survey,
    required this.l10n,
    required this.enabled,
  });

  final Survey survey;
  final AppLocalizations l10n;
  final bool enabled;

  String? _endsLabel() {
    final closesAt = survey.closesAt;
    if (closesAt == null) return null;
    final days = closesAt.difference(DateTime.now()).inDays;
    return days <= 0 ? l10n.surveysEndsToday : l10n.surveysEndsInDays(days);
  }

  @override
  Widget build(BuildContext context) {
    final presentation = _presentationFor(survey.id);
    final endsLabel = enabled ? _endsLabel() : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.foreground.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: enabled
            ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SurveyTakeScreen(surveyId: survey.id),
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: presentation.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  presentation.icon,
                  color: presentation.foreground,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      survey.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.foreground,
                      ),
                    ),
                    if (survey.description != null &&
                        survey.description!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        survey.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: _pointsStarColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          l10n.surveyPointsLabel(survey.points),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusPill(enabled: enabled, l10n: l10n),
                  if (endsLabel != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      endsLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.enabled, required this.l10n});

  final bool enabled;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.muted,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              size: 13,
              color: AppColors.mutedForeground,
            ),
            const SizedBox(width: 4),
            Text(
              l10n.surveysTabCompleted,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        l10n.surveyStartAction,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.success,
        ),
      ),
    );
  }
}
