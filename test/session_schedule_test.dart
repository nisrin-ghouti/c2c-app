import 'package:c2c/features/events/presentation/widgets/session_schedule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  DateTime startsAt,
  DateTime endsAt, {
  TextDirection textDirection = TextDirection.ltr,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: textDirection,
        child: Scaffold(
          body: Center(
            child: SessionSchedule(startsAt: startsAt, endsAt: endsAt),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('SessionSchedule', () {
    testWidgets('shows both dates and both times, with a dash between', (
      tester,
    ) async {
      await _pump(
        tester,
        DateTime(2026, 10, 12, 10, 0),
        DateTime(2026, 10, 12, 12, 30),
      );

      // The same-day end date is spelled out rather than abbreviated away.
      expect(find.text('12.10.2026'), findsNWidgets(2));
      expect(find.text('10:00'), findsOneWidget);
      expect(find.text('12:30'), findsOneWidget);
      expect(find.text('-'), findsOneWidget);
    });

    testWidgets('pads single-digit days, months and times', (tester) async {
      await _pump(
        tester,
        DateTime(2026, 3, 7, 9, 5),
        DateTime(2026, 3, 7, 11, 0),
      );

      expect(find.text('07.03.2026'), findsNWidgets(2));
      expect(find.text('09:05'), findsOneWidget);
      expect(find.text('11:00'), findsOneWidget);
    });

    testWidgets('spells out a different end date for a session past midnight', (
      tester,
    ) async {
      await _pump(
        tester,
        DateTime(2026, 9, 13, 20, 0),
        DateTime(2026, 9, 14, 20, 0),
      );

      expect(find.text('13.09.2026'), findsOneWidget);
      expect(find.text('14.09.2026'), findsOneWidget);
      // Both endpoints read 20:00 — the dates are what tell them apart, which
      // the old bare-time abbreviation lost entirely.
      expect(find.text('20:00'), findsNWidgets(2));
    });

    testWidgets('each time sits directly under its own date', (tester) async {
      await _pump(
        tester,
        DateTime(2026, 10, 12, 10, 0),
        DateTime(2026, 10, 12, 12, 30),
      );

      final startDate = tester.getCenter(find.text('12.10.2026').first);
      final startTime = tester.getCenter(find.text('10:00'));
      final endTime = tester.getCenter(find.text('12:30'));

      // Stacked: the time is below its date and horizontally centred on it.
      expect(startTime.dy, greaterThan(startDate.dy));
      expect((startTime.dx - startDate.dx).abs(), lessThan(1));
      // Start on the left, end on the right.
      expect(startTime.dx, lessThan(endTime.dx));
    });

    testWidgets('keeps start on the left even in an RTL locale', (
      tester,
    ) async {
      await _pump(
        tester,
        DateTime(2026, 10, 12, 10, 0),
        DateTime(2026, 10, 12, 12, 30),
        textDirection: TextDirection.rtl,
      );

      final startTime = tester.getCenter(find.text('10:00'));
      final endTime = tester.getCenter(find.text('12:30'));

      expect(startTime.dx, lessThan(endTime.dx));
    });
  });
}
