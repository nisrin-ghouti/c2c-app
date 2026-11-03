import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A session's schedule as two stacked date/time blocks either side of a dash:
///
/// ```
/// 12.10.2026  -  12.10.2026
///   10:00          12:30
/// ```
///
/// The end date is always spelled out, even when it matches the start. The
/// previous rendering abbreviated a same-day end to a bare time, which saved a
/// line but made the two endpoints read as different kinds of thing — and it
/// was the source of the `20:00 – 20:00` bug on sessions running past
/// midnight. Printing both dates costs nothing here and removes the special
/// case entirely.
class SessionSchedule extends StatelessWidget {
  const SessionSchedule({
    super.key,
    required this.startsAt,
    required this.endsAt,
    this.dateStyle,
    this.timeStyle,
  });

  final DateTime startsAt;
  final DateTime endsAt;

  /// Styling for the date line and the time line beneath it. The sessions
  /// table passes smaller text than the program detail cards do.
  final TextStyle? dateStyle;
  final TextStyle? timeStyle;

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String formatDate(DateTime dt) =>
      '${_two(dt.day)}.${_two(dt.month)}.${dt.year}';

  static String formatTime(DateTime dt) =>
      '${_two(dt.hour)}:${_two(dt.minute)}';

  @override
  Widget build(BuildContext context) {
    final date =
        dateStyle ?? const TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
    final time =
        timeStyle ??
        const TextStyle(fontSize: 12, color: AppColors.mutedForeground);

    // Pinned LTR in every locale: start on the left, end on the right. Under
    // the app's Hebrew/Arabic locales a plain Row would mirror, putting the
    // end first — and a numeric date range reads left-to-right regardless of
    // the surrounding script.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        // Top-aligned so the dash sits on the date line and each time stays
        // directly under its own date.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: _Endpoint(at: startsAt, dateStyle: date, timeStyle: time),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('-', style: date),
          ),
          Flexible(
            child: _Endpoint(at: endsAt, dateStyle: date, timeStyle: time),
          ),
        ],
      ),
    );
  }
}

/// One end of the range — its date, and its time centred underneath.
class _Endpoint extends StatelessWidget {
  const _Endpoint({
    required this.at,
    required this.dateStyle,
    required this.timeStyle,
  });

  final DateTime at;
  final TextStyle dateStyle;
  final TextStyle timeStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          SessionSchedule.formatDate(at),
          style: dateStyle,
          maxLines: 1,
          overflow: TextOverflow.visible,
        ),
        Text(
          SessionSchedule.formatTime(at),
          style: timeStyle,
          maxLines: 1,
          overflow: TextOverflow.visible,
        ),
      ],
    );
  }
}
