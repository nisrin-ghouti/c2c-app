import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_preferences.dart';
import '../../../../core/storage/shared_preferences_provider.dart';

/// Mirrors `hasChosenLanguageProvider` — a local, device-only flag (not
/// per-account) gating the onboarding tutorial into `app_router.dart`'s
/// `redirect` callback, right after the auth gate.
class OnboardingTutorialController extends StateNotifier<bool> {
  OnboardingTutorialController(this._prefs)
    : super(_prefs.hasSeenOnboardingTutorial);

  final AppPreferences _prefs;

  Future<void> markSeen() async {
    await _prefs.setHasSeenOnboardingTutorial(true);
    state = true;
  }

  /// Un-marks the tutorial as seen — used by "Replay App Introduction" in
  /// Settings. Reuses the exact same router gate that shows it the first
  /// time (`app_router.dart`'s redirect): once this flips to `false`, the
  /// very next navigation is redirected onto the tutorial automatically, no
  /// separate "replay" screen or navigation path needed.
  Future<void> reset() async {
    await _prefs.setHasSeenOnboardingTutorial(false);
    state = false;
  }
}

final onboardingTutorialControllerProvider =
    StateNotifierProvider<OnboardingTutorialController, bool>((ref) {
      return OnboardingTutorialController(ref.watch(appPreferencesProvider));
    });

final hasSeenOnboardingTutorialProvider = Provider<bool>((ref) {
  return ref.watch(onboardingTutorialControllerProvider);
});
