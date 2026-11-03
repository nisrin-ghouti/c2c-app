import '../entities/champions_announcement.dart';
import '../entities/leaderboard_entry.dart';
import '../entities/my_monthly_rank.dart';
import '../entities/point_transaction_entry.dart';
import '../repositories/points_repository.dart';

class GetMyTotalPoints {
  const GetMyTotalPoints(this._repository);
  final PointsRepository _repository;

  Future<int> call() => _repository.getMyTotalPoints();
}

class GetRecentTransactions {
  const GetRecentTransactions(this._repository);
  final PointsRepository _repository;

  Future<List<PointTransactionEntry>> call({int limit = 20}) {
    return _repository.getRecentTransactions(limit: limit);
  }
}

class GetMonthlyLeaderboard {
  const GetMonthlyLeaderboard(this._repository);
  final PointsRepository _repository;

  Future<List<LeaderboardEntry>> call({int limit = 100}) {
    return _repository.getMonthlyLeaderboard(limit: limit);
  }
}

class GetMyMonthlyRank {
  const GetMyMonthlyRank(this._repository);
  final PointsRepository _repository;

  Future<MyMonthlyRank> call() => _repository.getMyMonthlyRank();
}

class GetChampionsAnnouncement {
  const GetChampionsAnnouncement(this._repository);
  final PointsRepository _repository;

  Future<ChampionsAnnouncement?> call() =>
      _repository.getChampionsAnnouncement();
}

class MarkChampionsAnnouncementSeen {
  const MarkChampionsAnnouncementSeen(this._repository);
  final PointsRepository _repository;

  Future<void> call({required bool general, required bool winner}) =>
      _repository.markChampionsAnnouncementSeen(
        general: general,
        winner: winner,
      );
}
