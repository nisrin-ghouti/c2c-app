/// Outcome of `scan_event_attendance` — mirrors `MeetingClaimStatus`'s
/// shape, giving the UI a rich enough status to show the exact spec
/// strings ("Scanning is closed.", "You scanned after the time limit.",
/// "You have already scanned this event. You cannot scan it again.").
enum EventScanStatus {
  confirmed,
  scanningClosed,
  expired,
  alreadyScanned,
  notRegistered,
  invalid,
}

class EventScanResult {
  const EventScanResult({
    required this.status,
    this.points = 0,
    this.eventTitle,
  });

  final EventScanStatus status;
  final int points;
  final String? eventTitle;
}
