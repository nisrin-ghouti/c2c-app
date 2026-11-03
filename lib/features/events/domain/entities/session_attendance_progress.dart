/// How much of a multi-session Program the viewer has actually attended.
///
/// Every session of a program carries its own attendance barcode, so a single
/// `EventRegistrationStatus` can't describe the usual case — "2 of 4 sessions
/// done". Attendance rows scoped to a session are counted here instead of
/// flipping the whole program to `attended`, which is what used to happen
/// after the very first scan.
///
/// Null on a single event, where the tri-state alone says everything.
class SessionAttendanceProgress {
  const SessionAttendanceProgress({
    required this.attended,
    required this.total,
  });

  /// Sessions of this program the viewer has checked in to.
  final int attended;

  /// Sessions the program has in total.
  final int total;

  /// Every session attended. A program with no sessions yet is never complete
  /// — otherwise an empty program would read as fully attended.
  bool get isComplete => total > 0 && attended >= total;

  bool get hasAny => attended > 0;
}
