/// Shared by `MonthAnnouncementDialog` and `WinnerBonusDialog`.
String medalFor(int rank) => switch (rank) {
  1 => '🥇',
  2 => '🥈',
  3 => '🥉',
  _ => '🏆',
};
