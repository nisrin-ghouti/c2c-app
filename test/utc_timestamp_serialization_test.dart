import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards against the naive-local-timestamp trap.
///
/// `DateTime.now()` is LOCAL, and `toIso8601String()` emits **no offset** for a
/// local DateTime — `"2026-10-09T18:48:28.000"`. Postgres then reads that in
/// its own zone (UTC), so the value lands `timeZoneOffset` hours away from the
/// instant that was meant.
///
/// This shipped in `getUpcomingEvents()` from the first commit and hid every
/// event ending within the next 3 hours: an event starting in ten minutes sent
/// its "new event" push and then never appeared in the app. The same mistake
/// was in `getUpcomingEventCount()` and both `read_at` writes.
///
/// A source scan rather than a behavioural test, because the bug lives in a
/// one-line argument to a Supabase query builder — there is nothing to assert
/// on without a fake client, and the failure is silent at runtime. Catching the
/// *shape* is what actually prevents a recurrence.
void main() {
  test('no naive local timestamps are sent to Postgres', () {
    final offenders = <String>[];
    final pattern = RegExp(r'DateTime\.now\(\)\s*\.\s*toIso8601String\(\)');

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (pattern.hasMatch(lines[i])) {
          offenders.add('${entity.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Use DateTime.now().toUtc().toIso8601String(). A local DateTime '
          'serialises without a timezone offset, so Postgres reads it as UTC '
          'and the value is wrong by the local offset.\n'
          'Offending lines:\n${offenders.join('\n')}',
    );
  });

  test('toUtc() produces an instant Postgres cannot misread', () {
    final now = DateTime.now();
    final sent = now.toUtc().toIso8601String();

    // An explicit Z is what makes it unambiguous.
    expect(sent, endsWith('Z'));
    expect(DateTime.parse(sent).isAtSameMomentAs(now), isTrue);
  });

  test('the old form really was wrong (skipped on a UTC machine)', () {
    final now = DateTime.now();
    if (now.timeZoneOffset == Duration.zero) return;

    // What Postgres did with the old value: parse the offset-less string as
    // UTC. It lands timeZoneOffset away from the intended instant.
    final asPostgresRead = DateTime.parse('${now.toIso8601String()}Z');
    expect(asPostgresRead.isAtSameMomentAs(now), isFalse);
    expect(
      asPostgresRead.difference(now.toUtc()),
      now.timeZoneOffset,
    );
  });
}
