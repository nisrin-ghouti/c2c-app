import '../../domain/entities/submit_survey_result.dart';
import '../../domain/entities/survey.dart';
import '../../domain/entities/survey_answer_draft.dart';
import '../../domain/entities/survey_detail.dart';
import '../../domain/entities/survey_question.dart';
import '../../domain/entities/survey_question_type.dart';
import '../../domain/repositories/surveys_repository.dart';
import '../datasources/surveys_remote_data_source.dart';

class SurveysRepositoryImpl implements SurveysRepository {
  SurveysRepositoryImpl(this._remote);

  final SurveysRemoteDataSource _remote;

  @override
  Future<List<Survey>> listAvailableSurveys() async {
    final rows = await _remote.listAvailableSurveys();
    return rows.map(_surveyFromRow).toList();
  }

  @override
  Future<SurveyDetail> getSurveyDetail(String surveyId) async {
    final result = await _remote.getSurveyDetail(surveyId);
    final status = switch (result['status']) {
      'ok' => SurveyDetailStatus.ok,
      'not_yet_open' => SurveyDetailStatus.notYetOpen,
      'closed' => SurveyDetailStatus.closed,
      'already_answered' => SurveyDetailStatus.alreadyAnswered,
      _ => SurveyDetailStatus.notFound,
    };
    if (status != SurveyDetailStatus.ok) {
      return SurveyDetail(status: status);
    }

    final survey = Map<String, dynamic>.from(result['survey'] as Map);
    final questionRows = List<Map<String, dynamic>>.from(
      result['questions'] as List? ?? const [],
    );

    return SurveyDetail(
      status: status,
      info: SurveyDetailInfo(
        id: survey['id'] as String,
        title: survey['title'] as String,
        description: survey['description'] as String?,
        points: (survey['points'] as num?)?.toInt() ?? 0,
      ),
      questions: questionRows.map(_questionFromRow).toList(),
    );
  }

  @override
  Future<SubmitSurveyResult> submitSurveyResponse(
    String surveyId,
    List<SurveyAnswerDraft> answers,
  ) async {
    final result = await _remote.submitSurveyResponse(
      surveyId,
      answers.map((a) => a.toJson()).toList(),
    );
    final status = switch (result['status']) {
      'ok' => SubmitSurveyStatus.ok,
      'not_yet_open' => SubmitSurveyStatus.notYetOpen,
      'closed' => SubmitSurveyStatus.closed,
      'already_answered' => SubmitSurveyStatus.alreadyAnswered,
      'not_found' => SubmitSurveyStatus.notFound,
      _ => SubmitSurveyStatus.unknown,
    };
    return SubmitSurveyResult(
      status: status,
      points: (result['points'] as num?)?.toInt() ?? 0,
    );
  }

  Survey _surveyFromRow(Map<String, dynamic> row) {
    return Survey(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String?,
      points: (row['points'] as num?)?.toInt() ?? 0,
      opensAt: DateTime.parse(row['opens_at'] as String),
      closesAt: row['closes_at'] != null
          ? DateTime.parse(row['closes_at'] as String)
          : null,
      state: surveyStateFromDbValue(row['state'] as String),
    );
  }

  SurveyQuestion _questionFromRow(Map<String, dynamic> row) {
    final options = List<Map<String, dynamic>>.from(
      row['options'] as List? ?? const [],
    );
    return SurveyQuestion(
      id: row['id'] as String,
      type: SurveyQuestionType.fromDbValue(row['question_type'] as String),
      prompt: row['prompt'] as String,
      ratingMax: (row['rating_max'] as num?)?.toInt(),
      options: options
          .map(
            (o) => SurveyQuestionOption(
              id: o['id'] as String,
              label: o['label'] as String,
            ),
          )
          .toList(),
    );
  }
}
