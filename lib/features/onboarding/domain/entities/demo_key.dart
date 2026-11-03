/// Identifies one contextual, first-visit-only feature demo — each has its
/// own independent "seen" state (see `DemoFlagsController`), separate from
/// the global welcome tutorial and Home coach-mark tour.
enum DemoKey {
  eventCheckIn,
  meeting,
  groupMeeting,
  benefitsCatalog,
  digitalCard,
  matching,
  program,
  accessibility,
  notifications,
  champions,
  reportUser,
  chatControls,
}

extension DemoKeyStorage on DemoKey {
  /// Stable string used as part of the per-user `SharedPreferences` key —
  /// intentionally the enum's own name rather than `.toString()`'s
  /// `DemoKey.x` form, so it stays a normal, storage-safe identifier.
  String get storageKey => name;
}
