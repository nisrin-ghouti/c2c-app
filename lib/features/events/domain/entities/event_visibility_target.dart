/// One row of `event_visibility_targets` — a faculty name or a freeform
/// admin-typed group tag, only populated when the parent event's
/// `visibility` is `specificFaculties`/`specificGroups`.
class EventVisibilityTarget {
  const EventVisibilityTarget({required this.type, required this.value});

  /// `'faculty'` or `'group_tag'`.
  final String type;
  final String value;

  Map<String, dynamic> toJson() => {'target_type': type, 'target_value': value};
}
