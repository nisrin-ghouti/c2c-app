enum SurveyState { incoming, pending, completed }

SurveyState surveyStateFromDbValue(String value) => switch (value) {
  'incoming' => SurveyState.incoming,
  'completed' => SurveyState.completed,
  _ => SurveyState.pending,
};

/// One row of `list_available_surveys` — a survey's catalog/promo shape,
/// with the caller's own [state] already computed server-side.
class Survey {
  const Survey({
    required this.id,
    required this.title,
    this.description,
    required this.points,
    required this.opensAt,
    this.closesAt,
    required this.state,
  });

  final String id;
  final String title;
  final String? description;
  final int points;
  final DateTime opensAt;
  final DateTime? closesAt;
  final SurveyState state;
}
