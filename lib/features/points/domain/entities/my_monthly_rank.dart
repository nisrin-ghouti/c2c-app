/// `get_my_monthly_rank`'s result — the viewer's own position in this
/// month's ranking, plus what's needed to catch the person just above them.
enum MyMonthlyRankStatus {
  /// The viewer has a rank this month.
  ranked,

  /// The viewer hasn't earned any points this month yet.
  unranked,
}

class MyMonthlyRank {
  const MyMonthlyRank({
    required this.status,
    this.rank,
    this.points,
    this.aboveName,
    this.gap,
  });

  final MyMonthlyRankStatus status;
  final int? rank;
  final int? points;
  final String? aboveName;
  final int? gap;
}
