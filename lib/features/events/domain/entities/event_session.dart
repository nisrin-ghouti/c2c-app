import 'campus_event.dart';

/// One session of a multi-session Program — an independent event for
/// attendance/points purposes (own QR, own enable/disable, own scan-once
/// rule), even though registration itself happens once at the parent
/// program level. Reuses `EventRegistrationStatus` for the same
/// attended/registered/not-registered tri-state a `CampusEvent` carries.
class EventSession {
  const EventSession({
    required this.id,
    required this.eventId,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    this.location,
    this.qrEnabled = true,
    this.registrationStatus = EventRegistrationStatus.notRegistered,
    this.titleEn,
    this.titleAr,
    this.titleHe,
    this.locationEn,
    this.locationAr,
    this.locationHe,
  });

  final String id;
  final String eventId;
  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? location;
  final bool qrEnabled;
  final EventRegistrationStatus registrationStatus;

  /// Per-locale translations, filled by the `translate-content` edge function
  /// alongside the parent event's. `title`/`location` hold whatever the admin
  /// typed, in whatever language — so the `_en` slot is not assumed to equal
  /// the canonical value. Same shape as `CampusEvent`'s.
  final String? titleEn;
  final String? titleAr;
  final String? titleHe;
  final String? locationEn;
  final String? locationAr;
  final String? locationHe;

  /// The session title for [languageCode], falling back to the canonical text
  /// and then the other locales, so a missing translation never renders blank.
  String localizedTitle(String languageCode) =>
      _localize(languageCode, title, titleEn, titleAr, titleHe) ?? title;

  /// Same fallback rule as [localizedTitle], for the session's venue text.
  String? localizedLocation(String languageCode) =>
      _localize(languageCode, location, locationEn, locationAr, locationHe);

  static String? _localize(
    String languageCode,
    String? canonical,
    String? en,
    String? ar,
    String? he,
  ) {
    final ordered = switch (languageCode) {
      'ar' => [ar, canonical, en, he],
      'he' => [he, canonical, en, ar],
      _ => [en, canonical, he, ar],
    };
    for (final value in ordered) {
      if (value != null && value.trim().isNotEmpty) return value;
    }
    return null;
  }

  bool get hasStarted => DateTime.now().isAfter(startsAt);
  bool get hasEnded => DateTime.now().isAfter(endsAt);

  EventSession copyWith({EventRegistrationStatus? registrationStatus}) {
    return EventSession(
      id: id,
      eventId: eventId,
      title: title,
      startsAt: startsAt,
      endsAt: endsAt,
      location: location,
      qrEnabled: qrEnabled,
      registrationStatus: registrationStatus ?? this.registrationStatus,
      titleEn: titleEn,
      titleAr: titleAr,
      titleHe: titleHe,
      locationEn: locationEn,
      locationAr: locationAr,
      locationHe: locationHe,
    );
  }
}
