/// Summary counts for the Statistics screen's tiles, from `get_event_stats`.
class EventStats {
  const EventStats({
    required this.registered,
    required this.attended,
    required this.missed,
  });

  final int registered;
  final int attended;
  final int missed;
}
