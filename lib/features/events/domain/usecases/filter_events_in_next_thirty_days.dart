import '../entities/campus_event.dart';

/// The same clock time 30 calendar days after [from] — the closing edge of the
/// rolling window below.
///
/// Built by adding to the day field rather than `from.add(Duration(days: 30))`
/// so it stays 30 *calendar* days under local time. A fixed 30×24h duration
/// lands an hour early or late across a daylight-saving change, which would
/// quietly move the cut-off for everyone twice a year.
DateTime thirtyDaysAfter(DateTime from) => DateTime(
  from.year,
  from.month,
  from.day + 30,
  from.hour,
  from.minute,
  from.second,
  from.millisecond,
  from.microsecond,
);

/// The events of [events] taking place within the next 30 days of [now], in
/// the order they were given.
///
/// A rolling window, deliberately, not the calendar month: the section always
/// looks the same distance ahead, so it never thins out towards the end of a
/// month the way a "this month only" rule does. On 3 October it reaches 2
/// November; on 31 October it reaches 30 November.
///
/// An event qualifies when it starts before the window closes and hasn't
/// finished yet — so one already under way still counts (it is happening
/// inside the window), while one that has ended does not, however recently.
///
/// Programs are included on exactly the same terms as single events, and are
/// judged by [CampusEvent.effectiveStartsAt]/[CampusEvent.effectiveEndsAt] —
/// their sessions' real span — rather than the event row's own dates. A
/// program's typed start/end routinely disagrees with when it actually meets:
/// one live program carries a start seven weeks after its end, which placed it
/// outside every window and so hid it from this section entirely even though
/// its first session was days away. Nothing excludes an event for having
/// sessions; the sessions just decide when it is.
List<CampusEvent> filterEventsInNextThirtyDays(
  List<CampusEvent> events, {
  DateTime? now,
}) {
  final start = now ?? DateTime.now();
  final end = thirtyDaysAfter(start);
  return events
      .where(
        (event) =>
            !event.effectiveStartsAt.isAfter(end) &&
            event.effectiveEndsAt.isAfter(start),
      )
      .toList();
}
