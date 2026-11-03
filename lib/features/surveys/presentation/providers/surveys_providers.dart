import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../../../main.dart' show supabase;
import '../../data/datasources/surveys_remote_data_source.dart';
import '../../data/repositories/surveys_repository_impl.dart';
import '../../domain/entities/survey.dart';
import '../../domain/entities/survey_detail.dart';
import '../../domain/repositories/surveys_repository.dart';

final _surveysClientProvider = Provider<SupabaseClient>((ref) => supabase);

final _surveysRemoteDataSourceProvider = Provider<SurveysRemoteDataSource>((
  ref,
) {
  return SurveysRemoteDataSource(ref.watch(_surveysClientProvider));
});

final surveysRepositoryProvider = Provider<SurveysRepository>((ref) {
  return SurveysRepositoryImpl(ref.watch(_surveysRemoteDataSourceProvider));
});

/// Not `autoDispose` — read from both the Home teaser and the full list
/// screen, and re-fetched (`ref.invalidate`) after a submission, same
/// convention as `homeDashboardProvider`.
final availableSurveysProvider = FutureProvider<List<Survey>>((ref) {
  return ref.watch(surveysRepositoryProvider).listAvailableSurveys();
});

final surveyDetailProvider = FutureProvider.autoDispose
    .family<SurveyDetail, String>((ref, surveyId) {
      return ref.watch(surveysRepositoryProvider).getSurveyDetail(surveyId);
    });
