/// A profile's gender, stored in `profiles.gender` as a stable key so the
/// visible label can be localized (he/ar/en) rather than being a fixed
/// admin-entered string like the option-list fields.
enum Gender {
  male,
  female,
  undisclosed;

  String get dbValue => switch (this) {
    Gender.male => 'male',
    Gender.female => 'female',
    Gender.undisclosed => 'undisclosed',
  };

  /// Null for an unset/unrecognized value — gender is optional. A legacy
  /// 'other' value (removed as a choice) also falls back to null here; the
  /// DB migration that dropped it already rewrote existing rows to
  /// 'undisclosed', so this is just a defensive fallback for stale clients.
  static Gender? fromDbValue(String? value) => switch (value) {
    'male' => Gender.male,
    'female' => Gender.female,
    'undisclosed' => Gender.undisclosed,
    _ => null,
  };
}
