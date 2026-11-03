/// One answer being built on the "take survey" screen, before submission.
/// `answer` mirrors the shape the `submit_survey_response` RPC expects for
/// that question's type: `{"selected": [...]}`, `{"text": "..."}`, or
/// `{"rating": n}`.
class SurveyAnswerDraft {
  const SurveyAnswerDraft({required this.questionId, required this.answer});

  final String questionId;
  final Map<String, dynamic> answer;

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'answer': answer,
  };
}
