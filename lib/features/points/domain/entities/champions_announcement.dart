import '../../../../core/utils/initials.dart';

/// One top-3 finisher of a finalized month, with the bonus they earned.
class ChampionResult {
  const ChampionResult({
    required this.rank,
    required this.userId,
    required this.fullName,
    required this.avatarHue,
    this.avatarUrl,
    required this.points,
    required this.bonus,
  });

  final int rank;
  final String userId;
  final String fullName;
  final int avatarHue;
  final String? avatarUrl;
  final int points;
  final int bonus;

  String get initials => initialsOf(fullName);
}

/// Result of `get_champions_announcement` — drives the two mandatory
/// "OK only" popups: a general "last month's results are in" announcement
/// shown to everyone, and a personal winner popup shown only to the top 3.
class ChampionsAnnouncement {
  const ChampionsAnnouncement({
    required this.month,
    required this.top3,
    this.myRank,
    this.myPoints,
    this.myBonus,
    required this.hasUnseenGeneral,
    required this.hasUnseenWinner,
  });

  final DateTime month;
  final List<ChampionResult> top3;
  final int? myRank;
  final int? myPoints;
  final int? myBonus;
  final bool hasUnseenGeneral;
  final bool hasUnseenWinner;

  bool get amIWinner => myRank != null && myRank! <= 3;
  bool get hasAnyUnseen => hasUnseenGeneral || hasUnseenWinner;
}
