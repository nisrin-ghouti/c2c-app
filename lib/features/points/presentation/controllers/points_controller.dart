import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/my_monthly_rank.dart';
import '../../domain/entities/point_transaction_entry.dart';
import '../providers/points_providers.dart';

final myTotalPointsProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(getMyTotalPointsProvider)();
});

final recentTransactionsProvider =
    FutureProvider.autoDispose<List<PointTransactionEntry>>((ref) {
      return ref.watch(getRecentTransactionsProvider)();
    });

/// Bundles the leaderboard list + the viewer's own rank into one load, so
/// the Monthly Champions tab has a single loading/error state.
class MonthlyChampionsData {
  const MonthlyChampionsData({required this.leaderboard, required this.myRank});

  final List<LeaderboardEntry> leaderboard;
  final MyMonthlyRank myRank;
}

final monthlyChampionsDataProvider =
    FutureProvider.autoDispose<MonthlyChampionsData>((ref) async {
      final leaderboard = await ref.watch(getMonthlyLeaderboardProvider)();
      final myRank = await ref.watch(getMyMonthlyRankProvider)();
      return MonthlyChampionsData(leaderboard: leaderboard, myRank: myRank);
    });
