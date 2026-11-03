import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/app_preferences.dart';
import '../storage/shared_preferences_provider.dart';
import 'accessibility_settings.dart';

class AccessibilityController extends StateNotifier<AccessibilitySettings> {
  AccessibilityController(this._prefs) : super(_initial(_prefs));

  final AppPreferences _prefs;

  static AccessibilitySettings _initial(AppPreferences prefs) {
    return AccessibilitySettings(
      textScale: TextScaleOption.values.firstWhere(
        (option) => option.name == prefs.textScaleOptionName,
        orElse: () => TextScaleOption.normal,
      ),
      reduceMotion: prefs.reduceMotion,
      highContrast: prefs.highContrast,
    );
  }

  Future<void> setTextScale(TextScaleOption option) async {
    await _prefs.setTextScaleOptionName(option.name);
    state = state.copyWith(textScale: option);
  }

  Future<void> setReduceMotion(bool value) async {
    await _prefs.setReduceMotion(value);
    state = state.copyWith(reduceMotion: value);
  }

  Future<void> setHighContrast(bool value) async {
    await _prefs.setHighContrast(value);
    state = state.copyWith(highContrast: value);
  }
}

final accessibilitySettingsProvider =
    StateNotifierProvider<AccessibilityController, AccessibilitySettings>((
      ref,
    ) {
      return AccessibilityController(ref.watch(appPreferencesProvider));
    });
