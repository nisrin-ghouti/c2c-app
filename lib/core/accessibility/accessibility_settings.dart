/// Global text-size multiplier options — applied app-wide via
/// `MaterialApp.router`'s `builder` (see `app.dart`).
enum TextScaleOption { normal, large, extraLarge }

extension TextScaleOptionX on TextScaleOption {
  double get multiplier => switch (this) {
    TextScaleOption.normal => 1.0,
    TextScaleOption.large => 1.15,
    TextScaleOption.extraLarge => 1.3,
  };
}

/// The three device-local accessibility toggles — text scale, reduce
/// motion (shortens/skips the connection-celebration animation), and high
/// contrast (a global contrast boost, since the app's `AppColors` are
/// hardcoded constants rather than theme-resolved, swapping individual
/// colors per-widget isn't feasible without a much larger refactor).
class AccessibilitySettings {
  const AccessibilitySettings({
    this.textScale = TextScaleOption.normal,
    this.reduceMotion = false,
    this.highContrast = false,
  });

  final TextScaleOption textScale;
  final bool reduceMotion;
  final bool highContrast;

  AccessibilitySettings copyWith({
    TextScaleOption? textScale,
    bool? reduceMotion,
    bool? highContrast,
  }) {
    return AccessibilitySettings(
      textScale: textScale ?? this.textScale,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      highContrast: highContrast ?? this.highContrast,
    );
  }
}
