import '../../domain/entities/champions_announcement.dart';
import '../../domain/entities/leaderboard_entry.dart';
import '../../domain/entities/my_monthly_rank.dart';
import '../../domain/entities/point_transaction_entry.dart';
import '../../domain/repositories/points_repository.dart';
import '../datasources/points_remote_data_source.dart';

class PointsRepositoryImpl implements PointsRepository {
  PointsRepositoryImpl(this._remote);

  final PointsRemoteDataSource _remote;

  @override
  Future<int> getMyTotalPoints() => _remote.getMyPoints();

  @override
  Future<List<PointTransactionEntry>> getRecentTransactions({
    int limit = 20,
  }) async {
    final rows = await _remote.getRecentTransactions(limit: limit);
    return rows.map((row) {
      return PointTransactionEntry(
        id: row['id'] as String,
        amount: (row['amount'] as num).toInt(),
        reason: row['reason'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
    }).toList();
  }

  @override
  Future<List<LeaderboardEntry>> getMonthlyLeaderboard({
    int limit = 100,
  }) async {
    final rows = await _remote.getMonthlyLeaderboard(limit: limit);
    return rows.map((row) {
      return LeaderboardEntry(
        userId: row['user_id'] as String,
        fullName: (row['full_name'] as String?) ?? '',
        avatarHue: (row['avatar_hue'] as int?) ?? 220,
        avatarUrl: row['avatar_url'] as String?,
        points: (row['points'] as num?)?.toInt() ?? 0,
        rank: (row['rnk'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  @override
  Future<MyMonthlyRank> getMyMonthlyRank() async {
    final result = await _remote.getMyMonthlyRank();
    if (result == null || result['status'] != 'ok') {
      return const MyMonthlyRank(status: MyMonthlyRankStatus.unranked);
    }
    return MyMonthlyRank(
      status: MyMonthlyRankStatus.ranked,
      rank: (result['rank'] as num?)?.toInt(),
      points: (result['points'] as num?)?.toInt(),
      aboveName: result['above_name'] as String?,
      gap: (result['gap'] as num?)?.toInt(),
    );
  }

  @override
  Future<ChampionsAnnouncement?> getChampionsAnnouncement() async {
    final result = await _remote.getChampionsAnnouncement();
    if (result == null || result['status'] != 'ok') return null;

    final top3Rows = List<Map<String, dynamic>>.from(
      result['top3'] as List? ?? const [],
    );
    return ChampionsAnnouncement(
      month: DateTime.parse(result['month'] as String),
      top3: top3Rows.map((row) {
        return ChampionResult(
          rank: (row['rank'] as num).toInt(),
          userId: row['user_id'] as String,
          fullName: (row['full_name'] as String?) ?? '',
          avatarHue: (row['avatar_hue'] as int?) ?? 220,
          avatarUrl: row['avatar_url'] as String?,
          points: (row['points'] as num?)?.toInt() ?? 0,
          bonus: (row['bonus'] as num?)?.toInt() ?? 0,
        );
      }).toList(),
      myRank: (result['my_rank'] as num?)?.toInt(),
      myPoints: (result['my_points'] as num?)?.toInt(),
      myBonus: (result['my_bonus'] as num?)?.toInt(),
      hasUnseenGeneral: result['has_unseen_general'] as bool? ?? false,
      hasUnseenWinner: result['has_unseen_winner'] as bool? ?? false,
    );
  }

  @override
  Future<void> markChampionsAnnouncementSeen({
    required bool general,
    required bool winner,
  }) {
    return _remote.markChampionsAnnouncementSeen(
      general: general,
      winner: winner,
    );
  }
}
