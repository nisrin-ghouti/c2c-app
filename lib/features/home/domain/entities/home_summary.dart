/// The small stats shown at the top of the home dashboard.
class HomeSummary {
  const HomeSummary({
    required this.points,
    required this.unreadNotifications,
    required this.upcomingEventsCount,
  });

  final int points;
  final int unreadNotifications;
  final int upcomingEventsCount;
}
