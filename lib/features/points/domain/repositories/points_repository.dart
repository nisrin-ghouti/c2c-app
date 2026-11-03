import '../entities/champions_announcement.dart';
import '../entities/leaderboard_entry.dart';
import '../entities/my_monthly_rank.dart';
import '../entities/point_transaction_entry.dart';

abstract interface class PointsRepository {
  Future<int> getMyTotalPoints();

  /// Most recent ledger rows for the current user, newest first.
  Future<List<PointTransactionEntry>> getRecentTransactions({int limit = 20});

  Future<List<LeaderboardEntry>> getMonthlyLeaderboard({int limit = 100});

  Future<MyMonthlyRank> getMyMonthlyRank();

  /// `null` when no month has been finalized yet (before the first
  /// automated rollover runs).
  Future<ChampionsAnnouncement?> getChampionsAnnouncement();

  Future<void> markChampionsAnnouncementSeen({
    required bool general,
    required bool winner,
  });
}
