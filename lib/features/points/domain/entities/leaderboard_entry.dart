import '../../../../core/utils/initials.dart';

/// One row of `get_monthly_leaderboard` — a ranked student for the current
/// month's points competition.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.fullName,
    required this.avatarHue,
    required this.points,
    required this.rank,
    this.avatarUrl,
  });

  final String userId;
  final String fullName;
  final int avatarHue;
  final int points;
  final int rank;
  final String? avatarUrl;

  String get initials => initialsOf(fullName);
}
