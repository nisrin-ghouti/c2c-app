/// One row of `event_visibility_targets` — a faculty, a degree, or an
/// audience group id, only populated when the parent event's `visibility`
/// is `specificFaculties`/`specificGroups`.
class EventVisibilityTarget {
  const EventVisibilityTarget({required this.type, required this.value});

  /// `'faculty'`, `'degree'`, or `'audience_group'`.
  final String type;
  final String value;

  Map<String, dynamic> toJson() => {'target_type': type, 'target_value': value};
}
