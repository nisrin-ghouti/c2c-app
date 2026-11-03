import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/app_preferences.dart';
import '../storage/shared_preferences_provider.dart';

/// Where the floating accessibility button sits, as 0..1 fractions of the
/// draggable area (see [AppPreferences.accessibilityButtonX]). Null means
/// "never moved" — the button falls back to its default corner.
///
/// Deliberately kept OUT of `AccessibilitySettings`: `app.dart` watches that
/// object to rebuild `MaterialApp`, and this value changes on every drag.
class AccessibilityButtonPositionController extends StateNotifier<Offset?> {
  AccessibilityButtonPositionController(this._prefs) : super(_initial(_prefs));

  final AppPreferences _prefs;

  static Offset? _initial(AppPreferences prefs) {
    final x = prefs.accessibilityButtonX;
    final y = prefs.accessibilityButtonY;
    if (x == null || y == null) return null;
    return Offset(x, y);
  }

  Future<void> setPosition(Offset fraction) async {
    state = fraction;
    await _prefs.setAccessibilityButtonPosition(fraction.dx, fraction.dy);
  }
}

final accessibilityButtonPositionProvider =
    StateNotifierProvider<AccessibilityButtonPositionController, Offset?>((
      ref,
    ) {
      return AccessibilityButtonPositionController(
        ref.watch(appPreferencesProvider),
      );
    });

/// Whether the floating accessibility button is shown. Toggled from Settings
/// or by dragging the button onto the remove target.
class AccessibilityFloatingController extends StateNotifier<bool> {
  AccessibilityFloatingController(this._prefs)
    : super(_prefs.accessibilityFloatingEnabled);

  final AppPreferences _prefs;

  Future<void> setEnabled(bool value) async {
    state = value;
    await _prefs.setAccessibilityFloatingEnabled(value);
  }
}

final accessibilityFloatingEnabledProvider =
    StateNotifierProvider<AccessibilityFloatingController, bool>((ref) {
      return AccessibilityFloatingController(ref.watch(appPreferencesProvider));
    });
