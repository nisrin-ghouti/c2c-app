import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around the three student-facing survey RPCs
/// (`supabase/migrations/0027_surveys.sql`).
class SurveysRemoteDataSource {
  const SurveysRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> listAvailableSurveys() async {
    final result = await _client.rpc('list_available_surveys');
    return List<Map<String, dynamic>>.from(result as List? ?? const []);
  }

  Future<Map<String, dynamic>> getSurveyDetail(String surveyId) async {
    final result = await _client.rpc(
      'get_survey_detail',
      params: {'_survey_id': surveyId},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> submitSurveyResponse(
    String surveyId,
    List<Map<String, dynamic>> answers,
  ) async {
    final result = await _client.rpc(
      'submit_survey_response',
      params: {'_survey_id': surveyId, '_answers': answers},
    );
    return Map<String, dynamic>.from(result as Map);
  }
}
