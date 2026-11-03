import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/program_session_window.dart';

/// Thin wrapper around the raw Supabase table/RPC calls the events feature
/// needs. Only file in the feature allowed to reference `supabase_flutter`
/// types directly — `EventsRepositoryImpl` maps everything to domain
/// entities.
/// Parses a Postgres `timestamptz` that may arrive without a `Z`/offset
/// suffix. `DateTime.parse` reads a suffix-less string as local time, which
/// silently shifts the instant. Mirrors the helper in
/// `chat_repository_impl.dart`.
DateTime? _parseUtcTimestamp(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final hasOffset = RegExp(r'(Z|[+-]\d\d(:?\d\d)?)$').hasMatch(raw);
  final iso = raw.replaceFirst(' ', 'T');
  return DateTime.tryParse(hasOffset ? iso : '${iso}Z');
}

class EventsRemoteDataSource {
  const EventsRemoteDataSource(this._client);

  final SupabaseClient _client;

  String get currentUserId => _client.auth.currentUser!.id;

  static const _eventColumns =
      'id, title, description, category, location, starts_at, ends_at, points, image_url, '
      'created_by, organizer_name, organizer_description, external_link, '
      'event_kind, approval_status, rejection_reason, '
      'visibility, qr_enabled, capacity, registration_closed, '
      'title_ar, title_he, description_ar, description_he, '
      'location_ar, location_he, organizer_name_ar, organizer_name_he, '
      'organizer_description_ar, organizer_description_he, '
      'title_en, description_en, location_en, organizer_name_en, organizer_description_en';

  /// The browsable list: approved events that haven't finished yet,
  /// soonest-starting first.
  ///
  /// `toUtc()` before `toIso8601String()` is load-bearing, not tidiness.
  /// `DateTime.now()` is LOCAL, and `toIso8601String()` emits NO offset for a
  /// local DateTime ("2026-10-09T18:48:28.000"), so Postgres read it in the
  /// server's zone — UTC — and the app was asking for events ending at or
  /// after 18:48 *UTC* when the real time was 15:48 UTC. Every event ending
  /// within the next 3 hours (the Israel offset) was therefore invisible:
  /// create an event starting in ten minutes and it never appeared in the
  /// app, even though its "new event" push went out. Same trap, same fix, as
  /// `ChatRemoteDataSource.proposeMeeting`.
  Future<List<Map<String, dynamic>>> getUpcomingEvents() async {
    final rows = await _client
        .from('events')
        .select(_eventColumns)
        .eq('approval_status', 'approved')
        .gte('ends_at', DateTime.now().toUtc().toIso8601String())
        // ascending: true is REQUIRED. postgrest-dart's `order()` defaults to
        // `ascending: false`, so the "upcoming events" list came back
        // furthest-future first — and Home's preview, which takes the first
        // five, was showing the five LAST events of the window instead of the
        // five soonest.
        .order('starts_at', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Home's "Upcoming Events" stat. Must use the same instant, and the same
  /// `toUtc()`, as [getUpcomingEvents] — otherwise the count and the list it
  /// summarises disagree.
  Future<int> getUpcomingEventCount() async {
    final response = await _client
        .from('events')
        .select('id')
        .eq('approval_status', 'approved')
        .gte('ends_at', DateTime.now().toUtc().toIso8601String())
        .count(CountOption.exact);
    return response.count;
  }

  Future<List<Map<String, dynamic>>> getEventsByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await _client
        .from('events')
        .select(_eventColumns)
        .inFilter('id', ids);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Set<String>> getMyRegisteredEventIds() async {
    final rows = await _client
        .from('event_registrations')
        .select('event_id')
        .eq('user_id', currentUserId)
        .eq('status', 'registered');
    return List<Map<String, dynamic>>.from(
      rows,
    ).map((r) => r['event_id'] as String).toSet();
  }

  /// Events attended as a whole — attendance rows with no session on them.
  ///
  /// A Program's rows are session-scoped, and one scanned session says nothing
  /// about the rest of the program, so those are deliberately excluded here
  /// and counted by [getMyAttendedSessionCountsByEvent] instead. Without the
  /// filter the first session scanned flipped the entire program to
  /// "attended".
  Future<Set<String>> getMyAttendedEventIds() async {
    final rows = await _client
        .from('event_attendance')
        .select('event_id')
        .eq('user_id', currentUserId)
        .isFilter('session_id', null);
    return List<Map<String, dynamic>>.from(
      rows,
    ).map((r) => r['event_id'] as String).toSet();
  }

  /// event_id → how many distinct sessions of it the user has attended.
  Future<Map<String, int>> getMyAttendedSessionCountsByEvent() async {
    final rows = await _client
        .from('event_attendance')
        .select('event_id, session_id')
        .eq('user_id', currentUserId)
        .not('session_id', 'is', null);
    final seen = <String, Set<String>>{};
    for (final row in List<Map<String, dynamic>>.from(rows)) {
      seen
          .putIfAbsent(row['event_id'] as String, () => <String>{})
          .add(row['session_id'] as String);
    }
    return {for (final e in seen.entries) e.key: e.value.length};
  }

  /// event_id → its total session count, for the given events. Events without
  /// sessions are absent from the result rather than mapped to 0.
  /// event_id → session count AND the real date span of those sessions, for
  /// the given programs. Programs without sessions are absent.
  ///
  /// Selects the timestamps alongside the ids because a program's own
  /// `events.starts_at`/`ends_at` do not reliably describe when it meets (see
  /// `ProgramSessionWindow`), and this is already the one query that walks a
  /// program's sessions — so the span costs no extra round trip.
  Future<Map<String, ProgramSessionWindow>> getSessionCountsByEvent(
    List<String> eventIds,
  ) async {
    if (eventIds.isEmpty) return const {};
    final rows = await _client
        .from('event_sessions')
        .select('event_id, starts_at, ends_at')
        .inFilter('event_id', eventIds);

    final counts = <String, int>{};
    final firstStart = <String, DateTime>{};
    final lastEnd = <String, DateTime>{};
    for (final row in List<Map<String, dynamic>>.from(rows)) {
      final id = row['event_id'] as String;
      counts[id] = (counts[id] ?? 0) + 1;

      final startsAt = _parseUtcTimestamp(row['starts_at'] as String?);
      final endsAt = _parseUtcTimestamp(row['ends_at'] as String?);
      if (startsAt != null) {
        final current = firstStart[id];
        if (current == null || startsAt.isBefore(current)) {
          firstStart[id] = startsAt;
        }
      }
      if (endsAt != null) {
        final current = lastEnd[id];
        if (current == null || endsAt.isAfter(current)) {
          lastEnd[id] = endsAt;
        }
      }
    }

    return {
      for (final entry in counts.entries)
        // A session row with an unparseable or missing timestamp contributes
        // to the count but not to the span; if none of them parsed there is
        // no window to report and the caller keeps using the event row.
        if (firstStart[entry.key] != null && lastEnd[entry.key] != null)
          entry.key: ProgramSessionWindow(
            sessionCount: entry.value,
            firstStartsAt: firstStart[entry.key]!,
            lastEndsAt: lastEnd[entry.key]!,
          ),
    };
  }

  /// event_id → how many people hold a live registration, for the given
  /// events. Events with none are absent from the result.
  ///
  /// Goes through an RPC rather than a direct count: RLS only lets a student
  /// see their own `event_registrations` rows, so counting client-side would
  /// return 1 or 0 for every event. See migration 0065.
  Future<Map<String, int>> getRegistrationCountsByEvent(
    List<String> eventIds,
  ) async {
    if (eventIds.isEmpty) return const {};
    final result = await _client.rpc(
      'get_event_registration_counts',
      params: {'_event_ids': eventIds},
    );
    return {
      for (final entry in Map<String, dynamic>.from(result as Map).entries)
        entry.key: (entry.value as num).toInt(),
    };
  }

  /// The programs the viewer has been ACCEPTED onto — distinct from the ones
  /// they have merely registered for.
  ///
  /// A program with a selection step has two populations (migration 0071):
  /// everyone who applied (`event_registrations`) and the smaller set taken
  /// on (`program_accepted_participants`). Registered-but-not-accepted is
  /// what the app shows as "waiting for approval".
  ///
  /// RLS restricts this table to the caller's own rows
  /// (`program_accepted_select_self`), so this is the viewer's list and can't
  /// be used to enumerate anyone else's.
  Future<Set<String>> getMyAcceptedProgramIds() async {
    final rows = await _client
        .from('program_accepted_participants')
        .select('event_id')
        .eq('user_id', _client.auth.currentUser!.id);
    return {
      for (final row in List<Map<String, dynamic>>.from(rows))
        row['event_id'] as String,
    };
  }

  Future<Set<String>> getMyHostAccessEventIds() async {
    final rows = await _client
        .from('host_event_access')
        .select('event_id')
        .eq('host_user_id', currentUserId);
    return List<Map<String, dynamic>>.from(
      rows,
    ).map((r) => r['event_id'] as String).toSet();
  }

  Future<Map<String, dynamic>> registerForEvent(String eventId) async {
    final result = await _client.rpc(
      'register_for_event',
      params: {'_event_id': eventId},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> cancelEventRegistration(String eventId) async {
    final result = await _client.rpc(
      'cancel_event_registration',
      params: {'_event_id': eventId},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<void> deleteEvent(String eventId) {
    return _client.from('events').delete().eq('id', eventId);
  }

  Future<List<Map<String, dynamic>>> getEventRegistrants(
    String eventId, {
    String? sessionId,
  }) async {
    final result = await _client.rpc(
      'admin_list_event_registrants',
      params: {'_event_id': eventId, '_session_id': sessionId},
    );
    return List<Map<String, dynamic>>.from(result as List);
  }

  Future<List<Map<String, dynamic>>> getEventSessions(String eventId) async {
    final rows = await _client
        .from('event_sessions')
        .select(
          'id, event_id, title, starts_at, ends_at, location, qr_enabled, '
          'title_en, title_ar, title_he, '
          'location_en, location_ar, location_he',
        )
        .eq('event_id', eventId)
        // ascending: true is REQUIRED, not decorative. postgrest-dart's
        // `order()` defaults to `ascending: false`, so this returned a
        // program's sessions newest-first — meeting 5 above meeting 1. Same
        // trap `ChatRemoteDataSource.watchMessages` documents.
        .order('starts_at', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Set<String>> getMyAttendedSessionIds(String eventId) async {
    final rows = await _client
        .from('event_attendance')
        .select('session_id')
        .eq('event_id', eventId)
        .eq('user_id', currentUserId)
        .not('session_id', 'is', null);
    return List<Map<String, dynamic>>.from(
      rows,
    ).map((r) => r['session_id'] as String).toSet();
  }

  Future<Map<String, dynamic>> createEventOrProgram(
    Map<String, dynamic> event,
    List<Map<String, dynamic>>? sessions,
  ) async {
    final result = await _client.rpc(
      'create_event_or_program',
      params: {'_event': event, '_sessions': sessions},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> updateEventOrProgram(
    String eventId,
    Map<String, dynamic> event,
    List<Map<String, dynamic>>? sessions,
  ) async {
    final result = await _client.rpc(
      'update_event_or_program',
      params: {'_event_id': eventId, '_event': event, '_sessions': sessions},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<List<Map<String, dynamic>>> getPendingEvents() async {
    final result = await _client.rpc('admin_list_pending_events');
    return List<Map<String, dynamic>>.from(result as List);
  }

  Future<Map<String, dynamic>> approveEvent(String eventId) async {
    final result = await _client.rpc(
      'approve_event',
      params: {'_event_id': eventId},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> rejectEvent(
    String eventId,
    String reason,
  ) async {
    final result = await _client.rpc(
      'reject_event',
      params: {'_event_id': eventId, '_reason': reason},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> startEventQr(
    String eventId, {
    String? sessionId,
  }) async {
    final result = await _client.rpc(
      'start_event_qr',
      params: {'_event_id': eventId, '_session_id': sessionId},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<void> setEventQrEnabled(
    String eventId,
    bool enabled, {
    String? sessionId,
  }) async {
    await _client.rpc(
      'set_event_qr_enabled',
      params: {
        '_event_id': eventId,
        '_enabled': enabled,
        '_session_id': sessionId,
      },
    );
  }

  Future<Map<String, dynamic>> scanEventAttendance(String token) async {
    final result = await _client.rpc(
      'scan_event_attendance',
      params: {'_token': token},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> confirmAttendanceByStudentId(
    String eventId,
    String studentId, {
    String? sessionId,
  }) async {
    final result = await _client.rpc(
      'confirm_attendance_by_student_id',
      params: {
        '_event_id': eventId,
        '_student_id': studentId,
        '_session_id': sessionId,
      },
    );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>?> lookupStudentById(String studentId) async {
    final result = await _client.rpc(
      'lookup_student_by_id',
      params: {'_student_id': studentId},
    );
    return result == null ? null : Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> getEventStats(
    String eventId, {
    String? sessionId,
  }) async {
    final result = await _client.rpc(
      'get_event_stats',
      params: {'_event_id': eventId, '_session_id': sessionId},
    );
    return Map<String, dynamic>.from(result as Map);
  }

  /// Uploads an event image to the public `event-images` bucket and returns
  /// its public URL. Writes are open to any authenticated user because hosts
  /// — not only admins — create events.
  Future<String> uploadEventImage(File file) async {
    final extension = file.path.split('.').last.toLowerCase();
    final path =
        'event-${DateTime.now().millisecondsSinceEpoch}'
        '.${extension.isEmpty ? 'jpg' : extension}';

    await _client.storage
        .from('event-images')
        .upload(path, file, fileOptions: const FileOptions(upsert: true));
    return _client.storage.from('event-images').getPublicUrl(path);
  }
}
