import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../../../main.dart' show supabase;
import '../../../events/presentation/providers/events_providers.dart';
import '../../data/datasources/home_remote_data_source.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/repositories/home_repository.dart';
import '../../domain/usecases/load_home_dashboard.dart';

final _supabaseClientProvider = Provider<SupabaseClient>((ref) => supabase);

final _homeRemoteDataSourceProvider = Provider<HomeRemoteDataSource>((ref) {
  return HomeRemoteDataSource(ref.watch(_supabaseClientProvider));
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl(ref.watch(_homeRemoteDataSourceProvider));
});

final loadHomeDashboardProvider = Provider((ref) {
  return LoadHomeDashboard(
    ref.watch(homeRepositoryProvider),
    ref.watch(eventsRepositoryProvider),
  );
});
