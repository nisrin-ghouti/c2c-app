import 'dart:io';

import '../entities/campus_event.dart';
import '../entities/program_session_window.dart';
import '../entities/event_action_result.dart';
import '../entities/event_cancel_result.dart';
import '../entities/event_draft.dart';
import '../entities/event_qr_token.dart';
import '../entities/event_registrant.dart';
import '../entities/event_scan_result.dart';
import '../entities/event_session.dart';
import '../entities/event_stats.dart';
import '../entities/event_submit_result.dart';

/// The seam between the events feature's domain/presentation layers and
/// Supabase. See `EventsRemoteDataSource` for the actual table/RPC calls.
///
/// Carved out of the old `HomeRepository` (Phase B, Slice 1) — events grew
/// from "a list on the home dashboard" into a full subsystem (approval,
/// visibility, QR attendance, My Events), too big to keep bolted onto the
/// dashboard's repository.
abstract interface class EventsRepository {
  /// Approved, not-yet-ended events, soonest-starting first.
  Future<List<CampusEvent>> getUpcomingEvents();

  /// Count of [getUpcomingEvents] without fetching the rows — used only for
  /// the home dashboard's "Upcoming Events" stat-card number.
  Future<int> getUpcomingEventCount();

  /// Every event the current user has ever registered for or attended,
  /// regardless of whether it's already ended — the "My Events" screen's
  /// underlying data (unlike [getUpcomingEvents], which excludes the past).
  Future<List<CampusEvent>> getMyEvents();

  /// A single event by id, with the viewer's registration status stitched
  /// on — used to deep-link straight to an event (e.g. from a notification)
  /// without the caller already holding the object. Null if the event was
  /// deleted or the id is otherwise invalid.
  Future<CampusEvent?> getEventById(String eventId);

  /// Event ids the current user has registered for (whether or not attended).
  Future<Set<String>> getMyRegisteredEventIds();

  /// Event ids the current user has attended as a whole (subset of the
  /// above). A Program is attended session by session, so its attendance
  /// shows up in [getMyAttendedSessionCountsByEvent], not here.
  Future<Set<String>> getMyAttendedEventIds();

  /// event_id → how many of that event's sessions the user has attended.
  /// Pairs with [getSessionCountsByEvent] to tell "2 of 4 done" from "done".
  Future<Map<String, int>> getMyAttendedSessionCountsByEvent();

  /// event_id → its total session count, for the given events. Events with no
  /// sessions are absent rather than mapped to 0.
  Future<Map<String, ProgramSessionWindow>> getSessionCountsByEvent(
    List<String> eventIds,
  );

  /// The programs the viewer has been accepted onto. Registered-but-absent
  /// from this set is what the UI shows as awaiting approval.
  Future<Set<String>> getMyAcceptedProgramIds();

  /// event_id → its live registration count, for the given events. Events
  /// with no registrations are absent rather than mapped to 0.
  ///
  /// Compared against `CampusEvent.capacity` to show a full event as full
  /// before the student taps Register, instead of only refusing afterwards.
  Future<Map<String, int>> getRegistrationCountsByEvent(List<String> eventIds);

  /// Event ids the current user has been granted co-host access to (via
  /// `host_event_access`), regardless of whether they created the event.
  /// Fetched once per screen as a bulk set — see `EventPermissions.canManage`.
  Future<Set<String>> getMyHostAccessEventIds();

  Future<EventActionResult> registerForEvent(String eventId);

  /// Only succeeds if the event hasn't started yet.
  Future<EventCancelResult> cancelEventRegistration(String eventId);

  /// Admin-only, or the hosting/co-hosting user for their own event. Relies
  /// on RLS to reject anyone else.
  Future<void> deleteEvent(String eventId);

  /// Admin, or the hosting/co-hosting user for their own event.
  /// [sessionId] narrows "attended" to that one session of a Program —
  /// registration itself is always at the program level, only attendance
  /// is per-session.
  Future<List<EventRegistrant>> getEventRegistrants(
    String eventId, {
    String? sessionId,
  });

  /// A Program's sessions, chronological, with the viewer's own
  /// attended/registered/not-registered status stitched on per session.
  Future<List<EventSession>> getEventSessions(String eventId);

  /// Uploads event art and returns its public URL.
  Future<String> uploadEventImage(File file);

  /// Host/admin fallback when a QR can't be scanned: confirm attendance from
  /// the student's permanent Student ID. Returns the same result shape as a
  /// scan.
  Future<EventScanResult> confirmAttendanceByStudentId(
    String eventId,
    String studentId, {
    String? sessionId,
  });

  /// Resolves a Student ID to a display name so the UI can confirm *who* is
  /// about to be marked attended. Null when no student matches.
  Future<String?> lookupStudentNameById(String studentId);

  /// Host or admin only — starts as `pending` regardless of who creates it
  /// (no auto-approve fast path, even for admins).
  Future<EventSubmitResult> createEvent(EventDraft draft);

  /// Admin, or the hosting/co-hosting user for their own event. Editing an
  /// already-`approved` event reverts it to `pending` for re-review.
  Future<EventSubmitResult> updateEvent(String eventId, EventDraft draft);

  /// Admin-only — the approval queue.
  Future<List<CampusEvent>> getPendingEvents();

  Future<EventSubmitResult> approveEvent(String eventId);

  Future<EventSubmitResult> rejectEvent(String eventId, String reason);

  /// Host/admin only. Called once when the QR screen opens, then re-called
  /// every 10 seconds by `EventQrController` — returns `null` if the caller
  /// isn't allowed to manage this event. [sessionId] scopes the token to one
  /// Program session instead of the event itself.
  Future<EventQrToken?> startEventQr(String eventId, {String? sessionId});

  /// Host/admin only — enables/disables attendance scanning for the event
  /// (or, with [sessionId], just that one session).
  Future<void> setEventQrEnabled(
    String eventId,
    bool enabled, {
    String? sessionId,
  });

  /// Validates and, if everything checks out, records attendance + awards
  /// points atomically server-side. The token itself already encodes which
  /// event/session it belongs to.
  Future<EventScanResult> scanEventAttendance(String token);

  /// Host/admin only — registered/attended/missed counts for the
  /// Statistics screen. "Registered" always reflects the parent program's
  /// registration; "attended"/"missed" are scoped to [sessionId] when given.
  Future<EventStats> getEventStats(String eventId, {String? sessionId});
}
