import 'dart:io';

import '../../domain/entities/campus_event.dart';
import '../../domain/entities/program_session_window.dart';
import '../../domain/entities/event_action_result.dart';
import '../../domain/entities/event_approval_status.dart';
import '../../domain/entities/event_cancel_result.dart';
import '../../domain/entities/event_draft.dart';
import '../../domain/entities/event_kind.dart';
import '../../domain/entities/event_qr_token.dart';
import '../../domain/entities/event_registrant.dart';
import '../../domain/entities/event_scan_result.dart';
import '../../domain/entities/event_session.dart';
import '../../domain/entities/event_stats.dart';
import '../../domain/entities/event_submit_result.dart';
import '../../domain/entities/event_visibility.dart';
import '../../domain/repositories/events_repository.dart';
import '../../domain/usecases/stitch_registration_status.dart';
import '../datasources/events_remote_data_source.dart';

class EventsRepositoryImpl implements EventsRepository {
  EventsRepositoryImpl(this._remote);

  final EventsRemoteDataSource _remote;

  @override
  Future<List<CampusEvent>> getUpcomingEvents() async {
    final rows = await _remote.getUpcomingEvents();
    return rows.map(_eventFromRow).toList();
  }

  @override
  Future<int> getUpcomingEventCount() => _remote.getUpcomingEventCount();

  @override
  Future<List<CampusEvent>> getMyEvents() async {
    final results = await Future.wait([
      _remote.getMyRegisteredEventIds(),
      _remote.getMyAttendedEventIds(),
      _remote.getMyAttendedSessionCountsByEvent(),
    ]);
    final registeredIds = results[0] as Set<String>;
    final attendedIds = results[1] as Set<String>;
    final attendedSessionCounts = results[2] as Map<String, int>;
    // A program the student only ever scanned into per session shows up in
    // neither id set, so its own id has to come from the session counts too.
    final allIds = {
      ...registeredIds,
      ...attendedIds,
      ...attendedSessionCounts.keys,
    };
    if (allIds.isEmpty) return const [];

    final rows = await _remote.getEventsByIds(allIds.toList());
    final events = rows.map(_eventFromRow).toList();
    final sessionCounts = await _remote.getSessionCountsByEvent(
      _programIds(events),
    );

    return stitchRegistrationStatus(
      events,
      registeredIds: registeredIds,
      attendedIds: attendedIds,
      attendedSessionCounts: attendedSessionCounts,
      sessionCounts: sessionCounts,
    );
  }

  /// The ids of the programs in [events] — the only ones a session-count
  /// lookup has anything to say about.
  static List<String> _programIds(List<CampusEvent> events) => events
      .where((event) => event.eventKind == EventKind.program)
      .map((event) => event.id)
      .toList();

  @override
  Future<CampusEvent?> getEventById(String eventId) async {
    final results = await Future.wait([
      _remote.getEventsByIds([eventId]),
      _remote.getMyRegisteredEventIds(),
      _remote.getMyAttendedEventIds(),
      _remote.getMyAttendedSessionCountsByEvent(),
    ]);
    final rows = results[0] as List<Map<String, dynamic>>;
    if (rows.isEmpty) return null;
    final registeredIds = results[1] as Set<String>;
    final attendedIds = results[2] as Set<String>;
    final attendedSessionCounts = results[3] as Map<String, int>;
    final event = _eventFromRow(rows.first);
    final sessionCounts = await _remote.getSessionCountsByEvent(
      _programIds([event]),
    );

    return stitchEventRegistrationStatus(
      event,
      registeredIds: registeredIds,
      attendedIds: attendedIds,
      attendedSessionCounts: attendedSessionCounts,
      sessionCounts: sessionCounts,
    );
  }

  @override
  Future<Set<String>> getMyRegisteredEventIds() =>
      _remote.getMyRegisteredEventIds();

  @override
  Future<Set<String>> getMyAttendedEventIds() =>
      _remote.getMyAttendedEventIds();

  @override
  Future<Map<String, int>> getMyAttendedSessionCountsByEvent() =>
      _remote.getMyAttendedSessionCountsByEvent();

  @override
  Future<Map<String, ProgramSessionWindow>> getSessionCountsByEvent(
    List<String> eventIds,
  ) => _remote.getSessionCountsByEvent(eventIds);

  @override
  Future<Set<String>> getMyAcceptedProgramIds() =>
      _remote.getMyAcceptedProgramIds();

  @override
  Future<Map<String, int>> getRegistrationCountsByEvent(
    List<String> eventIds,
  ) => _remote.getRegistrationCountsByEvent(eventIds);

  @override
  Future<Set<String>> getMyHostAccessEventIds() =>
      _remote.getMyHostAccessEventIds();

  @override
  Future<EventActionResult> registerForEvent(String eventId) async {
    final result = await _remote.registerForEvent(eventId);
    return switch (result['status']) {
      'ok' => EventActionResult.ok,
      'already' => EventActionResult.alreadyRegistered,
      'full' => EventActionResult.full,
      'ended' => EventActionResult.ended,
      'not_published' => EventActionResult.notPublished,
      'event_not_found' => EventActionResult.notFound,
      _ => EventActionResult.unknown,
    };
  }

  @override
  Future<EventCancelResult> cancelEventRegistration(String eventId) async {
    final result = await _remote.cancelEventRegistration(eventId);
    return switch (result['status']) {
      'ok' => EventCancelResult.ok,
      'not_registered' => EventCancelResult.notRegistered,
      'already_started' => EventCancelResult.alreadyStarted,
      _ => EventCancelResult.unknown,
    };
  }

  @override
  Future<void> deleteEvent(String eventId) => _remote.deleteEvent(eventId);

  @override
  Future<List<EventRegistrant>> getEventRegistrants(
    String eventId, {
    String? sessionId,
  }) async {
    final rows = await _remote.getEventRegistrants(
      eventId,
      sessionId: sessionId,
    );
    return rows.map((row) {
      return EventRegistrant(
        userId: row['user_id'] as String,
        fullName: (row['full_name'] as String?) ?? '',
        email: row['email'] as String?,
        registeredAt: DateTime.parse(row['registered_at'] as String),
        attendedAt: row['attended_at'] != null
            ? DateTime.parse(row['attended_at'] as String)
            : null,
      );
    }).toList();
  }

  @override
  Future<List<EventSession>> getEventSessions(String eventId) async {
    final results = await Future.wait([
      _remote.getEventSessions(eventId),
      _remote.getMyRegisteredEventIds(),
      _remote.getMyAttendedSessionIds(eventId),
    ]);
    final rows = results[0] as List<Map<String, dynamic>>;
    final registeredEventIds = results[1] as Set<String>;
    final attendedSessionIds = results[2] as Set<String>;
    final isRegisteredForProgram = registeredEventIds.contains(eventId);

    return rows.map((row) {
      final id = row['id'] as String;
      final status = attendedSessionIds.contains(id)
          ? EventRegistrationStatus.attended
          : (isRegisteredForProgram
                ? EventRegistrationStatus.registered
                : EventRegistrationStatus.notRegistered);
      return EventSession(
        id: id,
        eventId: row['event_id'] as String,
        title: row['title'] as String,
        // .toLocal(): see `_eventFromRow`'s comment — same UTC-to-viewer's-
        // local-time fix.
        startsAt: DateTime.parse(row['starts_at'] as String).toLocal(),
        endsAt: DateTime.parse(row['ends_at'] as String).toLocal(),
        location: row['location'] as String?,
        qrEnabled: row['qr_enabled'] as bool? ?? true,
        registrationStatus: status,
        titleEn: row['title_en'] as String?,
        titleAr: row['title_ar'] as String?,
        titleHe: row['title_he'] as String?,
        locationEn: row['location_en'] as String?,
        locationAr: row['location_ar'] as String?,
        locationHe: row['location_he'] as String?,
      );
    }).toList();
  }

  @override
  Future<EventSubmitResult> createEvent(EventDraft draft) async {
    final result = await _remote.createEventOrProgram(
      draft.toEventJson(),
      draft.toSessionsJson(),
    );
    return _submitResultFrom(result['status'] as String?);
  }

  @override
  Future<EventSubmitResult> updateEvent(
    String eventId,
    EventDraft draft,
  ) async {
    final result = await _remote.updateEventOrProgram(
      eventId,
      draft.toEventJson(),
      draft.toSessionsJson(),
    );
    return _submitResultFrom(result['status'] as String?);
  }

  @override
  Future<List<CampusEvent>> getPendingEvents() async {
    final rows = await _remote.getPendingEvents();
    return rows.map(_eventFromRow).toList();
  }

  @override
  Future<EventSubmitResult> approveEvent(String eventId) async {
    final result = await _remote.approveEvent(eventId);
    return _submitResultFrom(result['status'] as String?);
  }

  @override
  Future<EventSubmitResult> rejectEvent(String eventId, String reason) async {
    final result = await _remote.rejectEvent(eventId, reason);
    return _submitResultFrom(result['status'] as String?);
  }

  EventSubmitResult _submitResultFrom(String? status) => switch (status) {
    'ok' => EventSubmitResult.ok,
    'forbidden' => EventSubmitResult.forbidden,
    'not_found' => EventSubmitResult.notFound,
    _ => EventSubmitResult.unknown,
  };

  @override
  Future<EventQrToken?> startEventQr(
    String eventId, {
    String? sessionId,
  }) async {
    final result = await _remote.startEventQr(eventId, sessionId: sessionId);
    if (result['status'] != 'ok') return null;
    return EventQrToken(
      token: result['token'] as String,
      expiresAt: DateTime.parse(result['expires_at'] as String),
    );
  }

  @override
  Future<void> setEventQrEnabled(
    String eventId,
    bool enabled, {
    String? sessionId,
  }) {
    return _remote.setEventQrEnabled(eventId, enabled, sessionId: sessionId);
  }

  @override
  Future<EventScanResult> scanEventAttendance(String token) async {
    final result = await _remote.scanEventAttendance(token);
    final status = switch (result['status']) {
      'ok' => EventScanStatus.confirmed,
      'scanning_closed' => EventScanStatus.scanningClosed,
      'expired' => EventScanStatus.expired,
      'already_scanned' => EventScanStatus.alreadyScanned,
      'not_registered' => EventScanStatus.notRegistered,
      _ => EventScanStatus.invalid,
    };
    return EventScanResult(
      status: status,
      points: (result['points'] as num?)?.toInt() ?? 0,
      eventTitle: result['event_title'] as String?,
    );
  }

  @override
  Future<EventStats> getEventStats(String eventId, {String? sessionId}) async {
    final result = await _remote.getEventStats(eventId, sessionId: sessionId);
    return EventStats(
      registered: (result['registered'] as num?)?.toInt() ?? 0,
      attended: (result['attended'] as num?)?.toInt() ?? 0,
      missed: (result['missed'] as num?)?.toInt() ?? 0,
    );
  }

  CampusEvent _eventFromRow(Map<String, dynamic> row) {
    return CampusEvent(
      id: row['id'] as String,
      title: row['title'] as String,
      category: row['category'] as String?,
      location: row['location'] as String?,
      // .toLocal(): Postgres returns starts_at/ends_at as UTC timestamptz
      // strings — converting here means every screen that reads this field
      // (formatting, comparisons against DateTime.now()) sees the viewer's
      // actual local time instead of raw UTC clock numbers.
      startsAt: DateTime.parse(row['starts_at'] as String).toLocal(),
      endsAt: DateTime.parse(row['ends_at'] as String).toLocal(),
      points: (row['points'] as int?) ?? 0,
      createdBy: row['created_by'] as String? ?? '',
      organizerName: row['organizer_name'] as String?,
      organizerDescription: row['organizer_description'] as String?,
      externalLink: row['external_link'] as String?,
      imageUrl: row['image_url'] as String?,
      description: row['description'] as String?,
      eventKind: EventKind.fromDbValue(
        (row['event_kind'] as String?) ?? 'single',
      ),
      approvalStatus: EventApprovalStatus.fromDbValue(
        (row['approval_status'] as String?) ?? 'approved',
      ),
      rejectionReason: row['rejection_reason'] as String?,
      visibility: EventVisibility.fromDbValue(
        (row['visibility'] as String?) ?? 'everyone',
      ),
      qrEnabled: row['qr_enabled'] as bool? ?? true,
      capacity: row['capacity'] as int?,
      // Absent for a caller that doesn't select the column, and null on a row
      // written before 0070 — both mean "not closed".
      registrationClosed: row['registration_closed'] as bool? ?? false,
      titleEn: row['title_en'] as String?,
      titleAr: row['title_ar'] as String?,
      titleHe: row['title_he'] as String?,
      descriptionEn: row['description_en'] as String?,
      descriptionAr: row['description_ar'] as String?,
      descriptionHe: row['description_he'] as String?,
      locationEn: row['location_en'] as String?,
      locationAr: row['location_ar'] as String?,
      locationHe: row['location_he'] as String?,
      organizerNameEn: row['organizer_name_en'] as String?,
      organizerNameAr: row['organizer_name_ar'] as String?,
      organizerNameHe: row['organizer_name_he'] as String?,
      organizerDescriptionEn: row['organizer_description_en'] as String?,
      organizerDescriptionAr: row['organizer_description_ar'] as String?,
      organizerDescriptionHe: row['organizer_description_he'] as String?,
    );
  }

  @override
  Future<String> uploadEventImage(File file) => _remote.uploadEventImage(file);

  @override
  Future<EventScanResult> confirmAttendanceByStudentId(
    String eventId,
    String studentId, {
    String? sessionId,
  }) async {
    final result = await _remote.confirmAttendanceByStudentId(
      eventId,
      studentId,
      sessionId: sessionId,
    );
    final status = switch (result['status']) {
      'ok' => EventScanStatus.confirmed,
      'scanning_closed' => EventScanStatus.scanningClosed,
      'expired' => EventScanStatus.expired,
      'already_scanned' => EventScanStatus.alreadyScanned,
      'not_registered' => EventScanStatus.notRegistered,
      _ => EventScanStatus.invalid,
    };
    return EventScanResult(
      status: status,
      points: (result['points'] as num?)?.toInt() ?? 0,
      eventTitle: result['event_title'] as String?,
    );
  }

  @override
  Future<String?> lookupStudentNameById(String studentId) async {
    final row = await _remote.lookupStudentById(studentId);
    return row?['full_name'] as String?;
  }
}
