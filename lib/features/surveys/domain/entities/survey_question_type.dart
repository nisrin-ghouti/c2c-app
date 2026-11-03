enum SurveyQuestionType {
  singleChoice,
  multiChoice,
  rating,
  text;

  String get dbValue => switch (this) {
    SurveyQuestionType.singleChoice => 'single_choice',
    SurveyQuestionType.multiChoice => 'multi_choice',
    SurveyQuestionType.rating => 'rating',
    SurveyQuestionType.text => 'text',
  };

  static SurveyQuestionType fromDbValue(String value) => switch (value) {
    'single_choice' => SurveyQuestionType.singleChoice,
    'multi_choice' => SurveyQuestionType.multiChoice,
    'rating' => SurveyQuestionType.rating,
    _ => SurveyQuestionType.text,
  };
}
