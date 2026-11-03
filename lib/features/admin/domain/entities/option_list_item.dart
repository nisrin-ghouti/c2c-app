import 'option_list_type.dart';

class OptionListItem {
  const OptionListItem({
    required this.id,
    required this.type,
    required this.label,
    this.labelAr,
    this.labelHe,
    required this.sortOrder,
    required this.active,
  });

  final String id;
  final OptionListType type;

  /// The canonical (English) label. Events and benefits store their category
  /// as this exact text, so it doubles as the row's identity — translations
  /// are separate columns rather than edits to this.
  final String label;

  final String? labelAr;
  final String? labelHe;

  /// The label to display for [languageCode] ('ar', 'he', anything else).
  /// Falls back to the canonical label when no translation was entered, so an
  /// untranslated option stays readable instead of rendering blank.
  String labelFor(String languageCode) {
    final translated = switch (languageCode) {
      'ar' => labelAr,
      'he' => labelHe,
      _ => null,
    };
    return (translated != null && translated.trim().isNotEmpty)
        ? translated
        : label;
  }

  final int sortOrder;
  final bool active;
}
