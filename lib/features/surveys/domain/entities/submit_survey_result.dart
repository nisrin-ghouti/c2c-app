enum SubmitSurveyStatus {
  ok,
  notFound,
  notYetOpen,
  closed,
  alreadyAnswered,
  unknown,
}

class SubmitSurveyResult {
  const SubmitSurveyResult({required this.status, this.points = 0});

  final SubmitSurveyStatus status;
  final int points;
}
