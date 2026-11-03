import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/app_preferences.dart';
import '../storage/shared_preferences_provider.dart';
import 'supported_locales.dart';

class LocaleController extends StateNotifier<Locale> {
  LocaleController(this._prefs) : super(_initialLocale(_prefs));

  final AppPreferences _prefs;

  static Locale _initialLocale(AppPreferences prefs) {
    return SupportedLocales.byCode(prefs.localeCode).locale;
  }

  Future<void> setLocale(Locale locale) async {
    await _prefs.setLocaleCode(locale.languageCode);
    state = locale;
  }

  // StateNotifier's default `updateShouldNotify` skips notifying listeners
  // when the new state is `identical()` to the old one. English is
  // `SupportedLocales.fallback`, a `const`, so it's also the very first
  // (pre-selection) state of this controller — picking English on the
  // language-selection screen would otherwise set `state` to that same
  // canonical const object and silently skip notifying, which broke
  // `hasChosenLanguageProvider` (it only re-evaluates by watching this
  // notification) and left the router redirecting back to the language
  // screen forever. Every explicit `setLocale` call is a real user action,
  // so always notify.
  @override
  bool updateShouldNotify(Locale old, Locale current) => true;
}

final localeControllerProvider =
    StateNotifierProvider<LocaleController, Locale>((ref) {
      return LocaleController(ref.watch(appPreferencesProvider));
    });

/// Whether the user has picked a language yet. The language-selection
/// screen is shown once, gating entry into the rest of the router, until
/// this becomes true.
final hasChosenLanguageProvider = Provider<bool>((ref) {
  ref.watch(localeControllerProvider); // re-evaluate once a locale is chosen
  return ref.watch(appPreferencesProvider).hasChosenLanguage;
});
