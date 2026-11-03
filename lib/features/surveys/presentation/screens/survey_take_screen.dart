import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_gradient_button.dart';
import '../../../../core/widgets/root_scaffold_messenger.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../domain/entities/submit_survey_result.dart';
import '../../domain/entities/survey_answer_draft.dart';
import '../../domain/entities/survey_detail.dart';
import '../../domain/entities/survey_question.dart';
import '../../domain/entities/survey_question_type.dart';
import '../controllers/submit_survey_controller.dart';
import '../providers/surveys_providers.dart';

class SurveyTakeScreen extends ConsumerStatefulWidget {
  const SurveyTakeScreen({super.key, required this.surveyId});

  final String surveyId;

  @override
  ConsumerState<SurveyTakeScreen> createState() => _SurveyTakeScreenState();
}

class _SurveyTakeScreenState extends ConsumerState<SurveyTakeScreen> {
  final Map<String, Map<String, dynamic>> _answers = {};
  bool _submitting = false;

  void _setAnswer(String questionId, Map<String, dynamic> value) {
    setState(() => _answers[questionId] = value);
  }

  bool _allAnswered(List<SurveyQuestion> questions) {
    for (final q in questions) {
      final a = _answers[q.id];
      if (a == null) return false;
      if (q.type == SurveyQuestionType.singleChoice ||
          q.type == SurveyQuestionType.multiChoice) {
        if ((a['selected'] as List?)?.isEmpty ?? true) return false;
      }
      if (q.type == SurveyQuestionType.text) {
        if ((a['text'] as String?)?.trim().isEmpty ?? true) return false;
      }
    }
    return true;
  }

  Future<void> _submit(
    String surveyId,
    List<SurveyQuestion> questions,
    AppLocalizations l10n,
  ) async {
    if (!_allAnswered(questions)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.surveyAnswerRequired)));
      return;
    }
    setState(() => _submitting = true);

    final answers = [
      for (final q in questions)
        SurveyAnswerDraft(questionId: q.id, answer: _answers[q.id]!),
    ];
    final result = await ref
        .read(submitSurveyControllerProvider.notifier)
        .submit(surveyId, answers);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result == null) return;

    if (result.status == SubmitSurveyStatus.ok) {
      ref.invalidate(homeDashboardProvider);
      // Uses the app-root messenger, not this screen's own — the screen is
      // popped on the next line, and a SnackBar shown via a local
      // `ScaffoldMessenger.of(context)` would be torn down along with the
      // popped route before it ever became visible.
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(l10n.surveySubmitSuccess(result.points))),
      );
      Navigator.of(context).pop();
      return;
    }

    final message = switch (result.status) {
      SubmitSurveyStatus.alreadyAnswered =>
        l10n.surveySubmitErrorAlreadyAnswered,
      SubmitSurveyStatus.closed => l10n.surveySubmitErrorClosed,
      SubmitSurveyStatus.notYetOpen => l10n.surveySubmitErrorNotYetOpen,
      _ => l10n.surveySubmitErrorGeneric,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detailAsync = ref.watch(surveyDetailProvider(widget.surveyId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.surveysTitle)),
      body: SafeArea(
        child: detailAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(l10n.surveyDetailLoadError)),
          data: (detail) {
            if (detail.status != SurveyDetailStatus.ok || detail.info == null) {
              final message = switch (detail.status) {
                SurveyDetailStatus.alreadyAnswered =>
                  l10n.surveySubmitErrorAlreadyAnswered,
                SurveyDetailStatus.closed => l10n.surveySubmitErrorClosed,
                SurveyDetailStatus.notYetOpen =>
                  l10n.surveySubmitErrorNotYetOpen,
                _ => l10n.surveyDetailLoadError,
              };
              return Center(child: Text(message));
            }

            final info = detail.info!;
            final questions = detail.questions ?? const [];

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        info.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      if (info.description != null &&
                          info.description!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          info.description!,
                          style: const TextStyle(
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        l10n.surveyPointsLabel(info.points),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryStrong,
                        ),
                      ),
                      const SizedBox(height: 20),
                      for (final question in questions) ...[
                        _QuestionCard(
                          question: question,
                          answer: _answers[question.id],
                          onChanged: (value) => _setAnswer(question.id, value),
                          l10n: l10n,
                        ),
                        const SizedBox(height: 14),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: PrimaryGradientButton(
                    label: l10n.surveySubmitAction,
                    loading: _submitting,
                    onPressed: () => _submit(widget.surveyId, questions, l10n),
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

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.answer,
    required this.onChanged,
    required this.l10n,
  });

  final SurveyQuestion question;
  final Map<String, dynamic>? answer;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.prompt,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 10),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildInput() {
    switch (question.type) {
      case SurveyQuestionType.singleChoice:
        final selectedList = (answer?['selected'] as List?)?.cast<String>();
        final selected = (selectedList != null && selectedList.isNotEmpty)
            ? selectedList.first
            : null;
        return Column(
          children: [
            RadioGroup<String>(
              groupValue: selected,
              onChanged: (value) {
                if (value != null) {
                  onChanged({
                    'selected': [value],
                  });
                }
              },
              child: Column(
                children: [
                  for (final option in question.options)
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        option.label,
                        style: const TextStyle(fontSize: 13),
                      ),
                      value: option.id,
                    ),
                ],
              ),
            ),
          ],
        );
      case SurveyQuestionType.multiChoice:
        final selected =
            (answer?['selected'] as List?)?.cast<String>().toSet() ??
            <String>{};
        return Column(
          children: [
            for (final option in question.options)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(option.label, style: const TextStyle(fontSize: 13)),
                value: selected.contains(option.id),
                onChanged: (checked) {
                  final next = Set<String>.of(selected);
                  if (checked ?? false) {
                    next.add(option.id);
                  } else {
                    next.remove(option.id);
                  }
                  onChanged({'selected': next.toList()});
                },
              ),
          ],
        );
      case SurveyQuestionType.rating:
        final max = question.ratingMax ?? 5;
        final rating = (answer?['rating'] as int?) ?? 0;
        return Row(
          children: [
            for (var i = 1; i <= max; i++)
              IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: AppColors.primaryStrong,
                ),
                onPressed: () => onChanged({'rating': i}),
              ),
          ],
        );
      case SurveyQuestionType.text:
        return TextField(
          maxLines: 3,
          decoration: InputDecoration(hintText: l10n.surveyTextAnswerHint),
          onChanged: (value) => onChanged({'text': value}),
        );
    }
  }
}
