import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../../../main.dart' show supabase;
import '../../data/datasources/points_remote_data_source.dart';
import '../../data/repositories/points_repository_impl.dart';
import '../../domain/entities/champions_announcement.dart';
import '../../domain/repositories/points_repository.dart';
import '../../domain/usecases/points_usecases.dart';

final _supabaseClientProvider = Provider<SupabaseClient>((ref) => supabase);

final _pointsRemoteDataSourceProvider = Provider<PointsRemoteDataSource>((ref) {
  return PointsRemoteDataSource(ref.watch(_supabaseClientProvider));
});

final pointsRepositoryProvider = Provider<PointsRepository>((ref) {
  return PointsRepositoryImpl(ref.watch(_pointsRemoteDataSourceProvider));
});

final getMyTotalPointsProvider = Provider(
  (ref) => GetMyTotalPoints(ref.watch(pointsRepositoryProvider)),
);
final getRecentTransactionsProvider = Provider(
  (ref) => GetRecentTransactions(ref.watch(pointsRepositoryProvider)),
);
final getMonthlyLeaderboardProvider = Provider(
  (ref) => GetMonthlyLeaderboard(ref.watch(pointsRepositoryProvider)),
);
final getMyMonthlyRankProvider = Provider(
  (ref) => GetMyMonthlyRank(ref.watch(pointsRepositoryProvider)),
);
final getChampionsAnnouncementProvider = Provider(
  (ref) => GetChampionsAnnouncement(ref.watch(pointsRepositoryProvider)),
);
final markChampionsAnnouncementSeenProvider = Provider(
  (ref) => MarkChampionsAnnouncementSeen(ref.watch(pointsRepositoryProvider)),
);

final championsAnnouncementProvider =
    FutureProvider.autoDispose<ChampionsAnnouncement?>((ref) {
      return ref.watch(getChampionsAnnouncementProvider)();
    });
