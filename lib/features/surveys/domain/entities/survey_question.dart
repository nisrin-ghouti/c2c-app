import 'survey_question_type.dart';

class SurveyQuestionOption {
  const SurveyQuestionOption({required this.id, required this.label});

  final String id;
  final String label;
}

/// One question of a survey, as shown on the "take survey" screen — from
/// `get_survey_detail`.
class SurveyQuestion {
  const SurveyQuestion({
    required this.id,
    required this.type,
    required this.prompt,
    this.ratingMax,
    this.options = const [],
  });

  final String id;
  final SurveyQuestionType type;
  final String prompt;

  /// Only meaningful when [type] is `rating`.
  final int? ratingMax;

  /// Only meaningful when [type] is `singleChoice`/`multiChoice`.
  final List<SurveyQuestionOption> options;
}
