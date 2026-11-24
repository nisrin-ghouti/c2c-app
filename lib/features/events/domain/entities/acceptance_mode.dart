/// How a student becomes a participant.
///
/// `auto` — registering is enough.
/// `approval` — registering only applies, until a host or admin accepts them.
enum AcceptanceMode {
  auto,
  approval;

  String get dbValue => switch (this) {
    AcceptanceMode.auto => 'auto',
    AcceptanceMode.approval => 'approval',
  };

  /// Null when the row did not carry the column, so callers can fall back
  /// to the historical rule (programs require approval, one-time events do
  /// not) instead of treating a missing value as a deliberate choice.
  static AcceptanceMode? tryParse(String? value) => switch (value) {
    'auto' => AcceptanceMode.auto,
    'approval' => AcceptanceMode.approval,
    _ => null,
  };
}
