import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around [SharedPreferences] for the handful of local-only
/// settings the app needs before/outside of any Supabase session (locale
/// choice, first-launch state). Keeping the keys here avoids typo'd string
/// literals scattered across the codebase.
class AppPreferences {
  const AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const _localeCodeKey = 'app.locale_code';
  static const _textScaleKey = 'app.text_scale';
  static const _reduceMotionKey = 'app.reduce_motion';
  static const _highContrastKey = 'app.high_contrast';
  static const _hasSeenOnboardingTutorialKey =
      'app.has_seen_onboarding_tutorial';
  static const _hasSeenHomeCoachMarkKey = 'app.has_seen_home_coach_mark';
  static const _accessibilityButtonXKey = 'app.accessibility_button_x';
  static const _accessibilityButtonYKey = 'app.accessibility_button_y';
  static const _accessibilityFloatingEnabledKey =
      'app.accessibility_floating_enabled';
  static const _tourResumeStepKey = 'app.tour_resume_step';

  String? get localeCode => _prefs.getString(_localeCodeKey);

  Future<void> setLocaleCode(String code) =>
      _prefs.setString(_localeCodeKey, code);

  /// The language-selection screen is shown once, the first time the app is
  /// ever launched — its completion is exactly "a locale has been chosen".
  bool get hasChosenLanguage => localeCode != null;

  /// Stored as the `TextScaleOption` enum's name (e.g. `"large"`).
  String? get textScaleOptionName => _prefs.getString(_textScaleKey);

  Future<void> setTextScaleOptionName(String name) =>
      _prefs.setString(_textScaleKey, name);

  bool get reduceMotion => _prefs.getBool(_reduceMotionKey) ?? false;

  Future<void> setReduceMotion(bool value) =>
      _prefs.setBool(_reduceMotionKey, value);

  bool get highContrast => _prefs.getBool(_highContrastKey) ?? false;

  Future<void> setHighContrast(bool value) =>
      _prefs.setBool(_highContrastKey, value);

  /// The onboarding tutorial is shown once per device, the first time a
  /// signed-in user reaches the app (after language + policy), mirroring
  /// [hasChosenLanguage]'s local, router-redirect-gated pattern.
  bool get hasSeenOnboardingTutorial =>
      _prefs.getBool(_hasSeenOnboardingTutorialKey) ?? false;

  Future<void> setHasSeenOnboardingTutorial(bool value) =>
      _prefs.setBool(_hasSeenOnboardingTutorialKey, value);

  /// The Home coach-mark tour (spotlighting the bottom nav + Home's own key
  /// buttons), shown the first time a given student lands on Home — separate
  /// from [hasSeenOnboardingTutorial], which gates the full-screen slide
  /// intro.
  ///
  /// Namespaced by [userId], like [hasSeenDemo]. It used to be a single
  /// device-wide key, which meant the SECOND account on a device never saw
  /// the tour at all: the flag was already true, Home skipped straight past
  /// it, and the only thing that fired was the accessibility demo — which is
  /// per-user and gated on this flag being true. New students on a shared or
  /// previously-used device got a broken half-tour.
  bool hasSeenHomeCoachMark(String userId) {
    _migrateLegacyHomeCoachMark(userId);
    return _prefs.getBool(_homeCoachMarkKey(userId)) ?? false;
  }

  Future<void> setHasSeenHomeCoachMark(String userId, bool value) =>
      _prefs.setBool(_homeCoachMarkKey(userId), value);

  String _homeCoachMarkKey(String userId) =>
      '$_hasSeenHomeCoachMarkKey.$userId';

  /// One-off carry-over of the old device-wide flag onto whichever account
  /// reads it first after upgrading, so existing users are not sent back
  /// through the tour. The legacy key is then removed, so any account
  /// created afterwards starts clean.
  void _migrateLegacyHomeCoachMark(String userId) {
    final legacy = _prefs.getBool(_hasSeenHomeCoachMarkKey);
    if (legacy == null) return;
    if (_prefs.getBool(_homeCoachMarkKey(userId)) == null) {
      _prefs.setBool(_homeCoachMarkKey(userId), legacy);
    }
    _prefs.remove(_hasSeenHomeCoachMarkKey);
  }

  /// Contextual per-feature demo "seen" state (event check-in, meeting,
  /// group meetings, benefits, matching, etc.) — unlike [hasSeenOnboardingTutorial]/
  /// [hasSeenHomeCoachMark], which are device-local only, these are namespaced
  /// by [userId] so a shared device signing out and into a different account
  /// doesn't inherit (or wrongly suppress) another student's "seen" demos.
  bool hasSeenDemo(String userId, String demoKey) =>
      _prefs.getBool(_demoSeenKey(userId, demoKey)) ?? false;

  Future<void> setHasSeenDemo(String userId, String demoKey) =>
      _prefs.setBool(_demoSeenKey(userId, demoKey), true);
  Future<void> resetDemo(String userId, String demoKey) =>
      _prefs.remove(_demoSeenKey(userId, demoKey));

  /// Un-marks every contextual demo as seen for [userId] — "Replay
  /// Tutorials" in Settings. Unlike "Replay App Introduction" (which resets
  /// the full-screen welcome tutorial + Home coach-mark and jumps straight
  /// to Home), this only clears the small per-feature tooltips, so each one
  /// simply reappears the next time its own screen is visited rather than
  /// forcing the user back through onboarding.
  Future<void> resetAllDemos(String userId) async {
    final prefix = 'app.demo_seen.$userId.';
    final keys = _prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  String _demoSeenKey(String userId, String demoKey) =>
      'app.demo_seen.$userId.$demoKey';

  /// Where the user dragged the floating accessibility button, stored as
  /// 0..1 fractions of the draggable area rather than pixels so the button
  /// lands in the same relative spot after a rotation or on another screen
  /// size. Null until the user moves it (i.e. still at the default corner).
  double? get accessibilityButtonX =>
      _prefs.getDouble(_accessibilityButtonXKey);

  double? get accessibilityButtonY =>
      _prefs.getDouble(_accessibilityButtonYKey);

  Future<void> setAccessibilityButtonPosition(double x, double y) async {
    await _prefs.setDouble(_accessibilityButtonXKey, x);
    await _prefs.setDouble(_accessibilityButtonYKey, y);
  }

  /// Whether the floating accessibility button is shown on screen. Users who
  /// don't want it always visible can drag it to the remove target (or toggle
  /// it here in Settings); the accessibility panel stays reachable from
  /// Profile → Settings regardless. Defaults to on.
  bool get accessibilityFloatingEnabled =>
      _prefs.getBool(_accessibilityFloatingEnabledKey) ?? true;

  Future<void> setAccessibilityFloatingEnabled(bool value) =>
      _prefs.setBool(_accessibilityFloatingEnabledKey, value);

  /// The step-by-step tour's current position (e.g. `"home.pointsBadge"` or
  /// `"matching.awaitingScanContent"`), written on every step transition so
  /// a page refresh mid-tour can resume from the exact step instead of
  /// losing progress. Null means no tour is currently in progress.
  String? get tourResumeStep => _prefs.getString(_tourResumeStepKey);

  Future<void> setTourResumeStep(String? value) => value == null
      ? _prefs.remove(_tourResumeStepKey)
      : _prefs.setString(_tourResumeStepKey, value);

  /// Whether this user has already been shown the centre-screen popup for one
  /// event reminder.
  ///
  /// Keyed by user + event + kind (`tomorrow`/`today`) + the event's own
  /// campus-local day, which is the same four-part key the server's
  /// `event_reminder_sends` ledger uses (migration 0076). Including the day is
  /// what makes a rescheduled event poppable again while never re-showing the
  /// same reminder.
  ///
  /// Local rather than server-side on purpose: "has this device shown this
  /// person a dialog" is device UI state, and the notification row itself is
  /// already the durable record — it stays in the notification centre whether
  /// the popup was shown or not.
  bool hasShownReminderPopup({
    required String userId,
    required String eventId,
    required String kind,
    required String eventDay,
  }) =>
      _prefs.getBool(
        _reminderPopupKey(userId, eventId, kind, eventDay),
      ) ??
      false;

  Future<void> setShownReminderPopup({
    required String userId,
    required String eventId,
    required String kind,
    required String eventDay,
  }) async {
    await _prefs.setBool(
      _reminderPopupKey(userId, eventId, kind, eventDay),
      true,
    );
    await _pruneReminderPopupKeys(userId, keep: eventDay);
  }

  /// Drops reminder-popup flags for days other than [keep].
  ///
  /// Without this the keys accumulate forever — one per event per reminder per
  /// day, for the life of the install. A flag for a past day can never be
  /// consulted again (the popup only ever considers the current campus day),
  /// so there is nothing to lose by removing it.
  Future<void> _pruneReminderPopupKeys(
    String userId, {
    required String keep,
  }) async {
    final prefix = 'app.reminder_popup.$userId.';
    final stale = _prefs
        .getKeys()
        .where((k) => k.startsWith(prefix) && !k.endsWith('.$keep'))
        .toList();
    for (final key in stale) {
      await _prefs.remove(key);
    }
  }

  String _reminderPopupKey(
    String userId,
    String eventId,
    String kind,
    String eventDay,
  ) => 'app.reminder_popup.$userId.$eventId.$kind.$eventDay';
}
