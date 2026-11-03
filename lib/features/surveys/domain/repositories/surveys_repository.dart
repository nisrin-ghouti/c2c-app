import '../entities/submit_survey_result.dart';
import '../entities/survey.dart';
import '../entities/survey_answer_draft.dart';
import '../entities/survey_detail.dart';

abstract interface class SurveysRepository {
  /// Every published survey visible to the caller, each tagged with its
  /// computed state — backs both the Home teaser and the full list screen.
  Future<List<Survey>> listAvailableSurveys();

  Future<SurveyDetail> getSurveyDetail(String surveyId);

  Future<SubmitSurveyResult> submitSurveyResponse(
    String surveyId,
    List<SurveyAnswerDraft> answers,
  );
}
