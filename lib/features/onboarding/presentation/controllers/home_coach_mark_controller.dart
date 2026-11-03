import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_preferences.dart';
import '../../../../core/storage/shared_preferences_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Mirrors `OnboardingTutorialController` — gates the Home coach-mark tour,
/// checked from `HomeScreen` itself (not the router) since this tour is an
/// in-place overlay, not a separate route.
///
/// Scoped to the signed-in user, like the contextual demo flags: a single
/// device-wide flag meant a second account on the same device silently
/// skipped the whole tour.
class HomeCoachMarkController extends StateNotifier<bool> {
  HomeCoachMarkController(this._prefs, this._userId)
    : super(_userId == null ? true : _prefs.hasSeenHomeCoachMark(_userId));

  final AppPreferences _prefs;
  final String? _userId;

  Future<void> markSeen() async {
    final userId = _userId;
    if (userId == null) return;
    state = true;
    await _prefs.setHasSeenHomeCoachMark(userId, true);
  }

  /// Un-marks the Home coach-mark tour as seen — paired with
  /// `OnboardingTutorialController.reset()` by "Replay App Introduction" in
  /// Settings. `HomeScreen`'s existing `!hasSeenHomeCoachMark` check
  /// re-triggers it automatically.
  Future<void> reset() async {
    final userId = _userId;
    if (userId == null) return;
    await _prefs.setHasSeenHomeCoachMark(userId, false);
    state = false;
  }
}

final homeCoachMarkControllerProvider =
    StateNotifierProvider<HomeCoachMarkController, bool>((ref) {
      // Rebuild on sign-in/out so a new account is evaluated against its own
      // flag rather than the previous student's.
      ref.watch(authSessionProvider);
      return HomeCoachMarkController(
        ref.watch(appPreferencesProvider),
        ref.watch(currentAuthSessionProvider).userId,
      );
    });

final hasSeenHomeCoachMarkProvider = Provider<bool>((ref) {
  return ref.watch(homeCoachMarkControllerProvider);
});
