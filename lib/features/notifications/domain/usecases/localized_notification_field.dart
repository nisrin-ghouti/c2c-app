/// Reads a translatable field out of a notification's `data` payload in the
/// app's current language.
///
/// The notify triggers copy an event's or benefit's per-locale columns into
/// `data` as `<field>_en` / `<field>_he` / `<field>_ar` alongside the canonical
/// `<field>` (migration 0075 for the publish/decision types, 0076 for the
/// reminders). This picks the one for [languageCode] and falls back the same
/// way `CampusEvent.localizedTitle` does:
///
///   1. the requested language,
///   2. the canonical value — whatever the organizer actually typed,
///   3. English, as a last resort when the canonical field itself is empty.
///
/// Returns an empty string when the payload carries none of them, so callers
/// can treat "" as "no title" and use their own generic copy. Rows written
/// before 0075 carry only the canonical field and therefore resolve to it,
/// which is exactly what they rendered before.
String localizedNotificationField(
  Map<String, dynamic> data,
  String field, {
  required String languageCode,
}) {
  for (final key in ['${field}_$languageCode', field, '${field}_en']) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) return value;
  }
  return '';
}
