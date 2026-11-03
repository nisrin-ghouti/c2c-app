import 'dart:io';

import '../entities/campus_event.dart';
import '../entities/event_action_result.dart';
import '../entities/event_cancel_result.dart';
import '../entities/event_draft.dart';
import '../entities/event_registrant.dart';
import '../entities/event_session.dart';
import '../entities/event_submit_result.dart';
import '../entities/event_scan_result.dart';
import '../repositories/events_repository.dart';

class RegisterForEvent {
  const RegisterForEvent(this._repository);
  final EventsRepository _repository;

  Future<EventActionResult> call(String eventId) =>
      _repository.registerForEvent(eventId);
}

class CancelEventRegistration {
  const CancelEventRegistration(this._repository);
  final EventsRepository _repository;

  Future<EventCancelResult> call(String eventId) =>
      _repository.cancelEventRegistration(eventId);
}

class DeleteEvent {
  const DeleteEvent(this._repository);
  final EventsRepository _repository;

  Future<void> call(String eventId) => _repository.deleteEvent(eventId);
}

class GetEventRegistrants {
  const GetEventRegistrants(this._repository);
  final EventsRepository _repository;

  Future<List<EventRegistrant>> call(String eventId, {String? sessionId}) =>
      _repository.getEventRegistrants(eventId, sessionId: sessionId);
}

class GetEventSessions {
  const GetEventSessions(this._repository);
  final EventsRepository _repository;

  Future<List<EventSession>> call(String eventId) =>
      _repository.getEventSessions(eventId);
}

class CreateEvent {
  const CreateEvent(this._repository);
  final EventsRepository _repository;

  Future<EventSubmitResult> call(EventDraft draft) =>
      _repository.createEvent(draft);
}

class UpdateEvent {
  const UpdateEvent(this._repository);
  final EventsRepository _repository;

  Future<EventSubmitResult> call(String eventId, EventDraft draft) =>
      _repository.updateEvent(eventId, draft);
}

class GetPendingEvents {
  const GetPendingEvents(this._repository);
  final EventsRepository _repository;

  Future<List<CampusEvent>> call() => _repository.getPendingEvents();
}

class ApproveEvent {
  const ApproveEvent(this._repository);
  final EventsRepository _repository;

  Future<EventSubmitResult> call(String eventId) =>
      _repository.approveEvent(eventId);
}

class RejectEvent {
  const RejectEvent(this._repository);
  final EventsRepository _repository;

  Future<EventSubmitResult> call(String eventId, String reason) =>
      _repository.rejectEvent(eventId, reason);
}

class UploadEventImage {
  const UploadEventImage(this._repository);
  final EventsRepository _repository;

  Future<String> call(File file) => _repository.uploadEventImage(file);
}

class ConfirmAttendanceByStudentId {
  const ConfirmAttendanceByStudentId(this._repository);
  final EventsRepository _repository;

  Future<EventScanResult> call(
    String eventId,
    String studentId, {
    String? sessionId,
  }) => _repository.confirmAttendanceByStudentId(
    eventId,
    studentId,
    sessionId: sessionId,
  );
}

class LookupStudentNameById {
  const LookupStudentNameById(this._repository);
  final EventsRepository _repository;

  Future<String?> call(String studentId) =>
      _repository.lookupStudentNameById(studentId);
}
