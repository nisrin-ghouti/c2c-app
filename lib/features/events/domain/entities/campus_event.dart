import 'event_approval_status.dart';
import 'program_session_window.dart';
import 'event_kind.dart';
import 'event_visibility.dart';
import 'session_attendance_progress.dart';

/// Whether/how the current user is registered for a [CampusEvent].
enum EventRegistrationStatus { notRegistered, registered, attended }

/// A published event, as shown on the campus events list.
class CampusEvent {
  const CampusEvent({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.startsAt,
    required this.endsAt,
    required this.points,
    required this.createdBy,
    this.organizerName,
    this.organizerDescription,
    this.externalLink,
    this.imageUrl,
    this.description,
    this.eventKind = EventKind.single,
    this.approvalStatus = EventApprovalStatus.approved,
    this.rejectionReason,
    this.visibility = EventVisibility.everyone,
    this.qrEnabled = true,
    this.capacity,
    this.registrationClosed = false,
    this.registrationStatus = EventRegistrationStatus.notRegistered,
    this.sessionAttendance,
    this.sessionWindow,
    this.titleEn,
    this.titleAr,
    this.titleHe,
    this.descriptionEn,
    this.descriptionAr,
    this.descriptionHe,
    this.locationEn,
    this.locationAr,
    this.locationHe,
    this.organizerNameEn,
    this.organizerNameAr,
    this.organizerNameHe,
    this.organizerDescriptionEn,
    this.organizerDescriptionAr,
    this.organizerDescriptionHe,
  });

  final String id;
  final String title;
  final String? category;
  final String? location;
  final DateTime startsAt;
  final DateTime endsAt;
  final int points;

  /// The host (`profiles.id`) who created this event — used to gate
  /// host-only management actions and to derive the organizer filter.
  final String createdBy;
  final String? organizerName;

  /// Spec Event Profile fields — 'About the organizer' and a social/website
  /// link (Instagram, Facebook, ...).
  final String? organizerDescription;
  final String? externalLink;
  final String? imageUrl;
  final String? description;
  final EventKind eventKind;
  final EventApprovalStatus approvalStatus;
  final String? rejectionReason;
  final EventVisibility visibility;
  final bool qrEnabled;
  final int? capacity;

  /// Whether an admin or host has manually closed registration, independently
  /// of capacity (`set_event_registration_closed`, migration 0070).
  ///
  /// Separate from "full" on purpose: a closed event may still have places, or
  /// no cap at all. Defaults to false so a row from before 0070 — or a caller
  /// that doesn't select the column — stays registerable.
  final bool registrationClosed;
  final EventRegistrationStatus registrationStatus;

  /// For a Program, how many of its sessions the viewer has attended — see
  /// [SessionAttendanceProgress]. Null for a single event, and for a program
  /// fetched by a screen that doesn't need the per-session breakdown.
  final SessionAttendanceProgress? sessionAttendance;

  /// For a Program, the real span of its sessions. Null for a single event,
  /// and for a program whose sessions haven't been loaded or carry no usable
  /// timestamps — in which case the event row's own dates stand.
  final ProgramSessionWindow? sessionWindow;

  /// When this event actually begins, for date rules (lists, the next-month
  /// window, "has it started").
  ///
  /// A program's `starts_at` is whatever was typed into the event form and
  /// routinely disagrees with its sessions — one live program has its start
  /// seven weeks AFTER its end, with sessions running between neither. The
  /// sessions are the schedule, so they win whenever they are known.
  DateTime get effectiveStartsAt => sessionWindow?.firstStartsAt ?? startsAt;

  /// When it actually finishes. Same reasoning as [effectiveStartsAt].
  DateTime get effectiveEndsAt => sessionWindow?.lastEndsAt ?? endsAt;

  /// Per-locale translations, auto-filled by the `translate-content` edge
  /// function (or hand-entered by an admin) — stored directly on the event
  /// row, same additive-columns pattern as `option_lists.label_ar`/`label_he`.
  /// `title`/`description`/etc. (undecorated) hold whatever the admin
  /// originally typed, in whatever language that happened to be — the `_en`
  /// slot is NOT assumed to equal the canonical field, since the canonical
  /// text itself might not be in English.
  final String? titleEn;
  final String? titleAr;
  final String? titleHe;
  final String? descriptionEn;
  final String? descriptionAr;
  final String? descriptionHe;
  final String? locationEn;
  final String? locationAr;
  final String? locationHe;
  final String? organizerNameEn;
  final String? organizerNameAr;
  final String? organizerNameHe;
  final String? organizerDescriptionEn;
  final String? organizerDescriptionAr;
  final String? organizerDescriptionHe;

  bool get hasStarted => DateTime.now().isAfter(startsAt);
  bool get hasEnded => DateTime.now().isAfter(endsAt);

  static String? _localize(
    String languageCode,
    String? canonical,
    String? en,
    String? ar,
    String? he,
  ) {
    final translated = switch (languageCode) {
      'en' => en,
      'ar' => ar,
      'he' => he,
      _ => null,
    };
    if (translated != null && translated.trim().isNotEmpty) return translated;
    return canonical;
  }

  /// The title to show for [languageCode] — falls back to the canonical
  /// [title] whenever no translation was entered for that locale.
  String localizedTitle(String languageCode) =>
      _localize(languageCode, title, titleEn, titleAr, titleHe)!;

  /// The description to show for [languageCode] — same fallback rule as
  /// [localizedTitle]. Null (not empty string) when there's no description
  /// in any language, same as [description] itself.
  String? localizedDescription(String languageCode) => _localize(
    languageCode,
    description,
    descriptionEn,
    descriptionAr,
    descriptionHe,
  );

  /// Same fallback rule as [localizedTitle], for the venue/address text.
  String? localizedLocation(String languageCode) =>
      _localize(languageCode, location, locationEn, locationAr, locationHe);

  /// Same fallback rule as [localizedTitle], for the organizer's display name.
  String? localizedOrganizerName(String languageCode) => _localize(
    languageCode,
    organizerName,
    organizerNameEn,
    organizerNameAr,
    organizerNameHe,
  );

  /// Same fallback rule as [localizedTitle], for the "About the organizer" text.
  String? localizedOrganizerDescription(String languageCode) => _localize(
    languageCode,
    organizerDescription,
    organizerDescriptionEn,
    organizerDescriptionAr,
    organizerDescriptionHe,
  );

  CampusEvent copyWith({
    EventRegistrationStatus? registrationStatus,
    SessionAttendanceProgress? sessionAttendance,
    ProgramSessionWindow? sessionWindow,
    EventApprovalStatus? approvalStatus,
    bool? qrEnabled,
  }) {
    return CampusEvent(
      id: id,
      title: title,
      category: category,
      location: location,
      startsAt: startsAt,
      endsAt: endsAt,
      points: points,
      createdBy: createdBy,
      organizerName: organizerName,
      organizerDescription: organizerDescription,
      externalLink: externalLink,
      imageUrl: imageUrl,
      description: description,
      eventKind: eventKind,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      rejectionReason: rejectionReason,
      visibility: visibility,
      qrEnabled: qrEnabled ?? this.qrEnabled,
      capacity: capacity,
      registrationClosed: registrationClosed,
      registrationStatus: registrationStatus ?? this.registrationStatus,
      sessionAttendance: sessionAttendance ?? this.sessionAttendance,
      sessionWindow: sessionWindow ?? this.sessionWindow,
      titleEn: titleEn,
      titleAr: titleAr,
      titleHe: titleHe,
      descriptionEn: descriptionEn,
      descriptionAr: descriptionAr,
      descriptionHe: descriptionHe,
      locationEn: locationEn,
      locationAr: locationAr,
      locationHe: locationHe,
      organizerNameEn: organizerNameEn,
      organizerNameAr: organizerNameAr,
      organizerNameHe: organizerNameHe,
      organizerDescriptionEn: organizerDescriptionEn,
      organizerDescriptionAr: organizerDescriptionAr,
      organizerDescriptionHe: organizerDescriptionHe,
    );
  }
}
