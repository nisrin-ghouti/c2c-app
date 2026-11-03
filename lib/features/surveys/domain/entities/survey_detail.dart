import 'survey_question.dart';

enum SurveyDetailStatus { ok, notFound, notYetOpen, closed, alreadyAnswered }

class SurveyDetailInfo {
  const SurveyDetailInfo({
    required this.id,
    required this.title,
    this.description,
    required this.points,
  });

  final String id;
  final String title;
  final String? description;
  final int points;
}

/// From `get_survey_detail` — the survey plus the questions to render on
/// the "take survey" screen. `info`/`questions` are null unless [status]
/// is `ok`.
class SurveyDetail {
  const SurveyDetail({required this.status, this.info, this.questions});

  final SurveyDetailStatus status;
  final SurveyDetailInfo? info;
  final List<SurveyQuestion>? questions;
}
