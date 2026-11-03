import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/submit_survey_result.dart';
import '../../domain/entities/survey_answer_draft.dart';
import '../providers/surveys_providers.dart';

class SubmitSurveyController extends StateNotifier<AsyncValue<void>> {
  SubmitSurveyController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<SubmitSurveyResult?> submit(
    String surveyId,
    List<SurveyAnswerDraft> answers,
  ) async {
    state = const AsyncLoading();
    try {
      final result = await _ref
          .read(surveysRepositoryProvider)
          .submitSurveyResponse(surveyId, answers);
      state = const AsyncData(null);
      if (result.status == SubmitSurveyStatus.ok) {
        _ref.invalidate(availableSurveysProvider);
      }
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }
}

final submitSurveyControllerProvider =
    StateNotifierProvider.autoDispose<SubmitSurveyController, AsyncValue<void>>(
      (ref) {
        return SubmitSurveyController(ref);
      },
    );
