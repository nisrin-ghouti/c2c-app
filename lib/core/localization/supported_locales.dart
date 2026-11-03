import 'package:flutter/material.dart';

/// Metadata for a locale the app supports, used by the language-selection
/// screen and by [AppTheme] to pick the right font family per script.
class AppLocale {
  const AppLocale({
    required this.locale,
    required this.nativeName,
    required this.englishName,
  });

  final Locale locale;

  /// Name shown in the language's own script (e.g. "עברית").
  final String nativeName;

  /// Name shown for reference (e.g. "Hebrew").
  final String englishName;

  bool get isRtl => locale.languageCode == 'he' || locale.languageCode == 'ar';
}

abstract final class SupportedLocales {
  static const english = AppLocale(
    locale: Locale('en'),
    nativeName: 'English',
    englishName: 'English',
  );

  static const hebrew = AppLocale(
    locale: Locale('he'),
    nativeName: 'עברית',
    englishName: 'Hebrew',
  );

  static const arabic = AppLocale(
    locale: Locale('ar'),
    nativeName: 'العربية',
    englishName: 'Arabic',
  );

  static const all = [english, hebrew, arabic];

  static const fallback = english;

  static AppLocale byCode(String? languageCode) {
    return all.firstWhere(
      (l) => l.locale.languageCode == languageCode,
      orElse: () => fallback,
    );
  }
}
