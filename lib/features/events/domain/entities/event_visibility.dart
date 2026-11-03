/// Who may see/register for an event. `specificFaculties`/`specificGroups`
/// are backed by `event_visibility_targets` rows (faculty name or a
/// freeform admin-typed group tag — no real group-membership entity for
/// v1, per the expansion plan's decision). Editing this is Slice 2 work;
/// the enum exists from Slice 1 so the entity shape is stable.
enum EventVisibility {
  onlyMe,
  everyone,
  specificFaculties,
  specificGroups;

  String get dbValue => switch (this) {
    EventVisibility.onlyMe => 'only_me',
    EventVisibility.everyone => 'everyone',
    EventVisibility.specificFaculties => 'specific_faculties',
    EventVisibility.specificGroups => 'specific_groups',
  };

  static EventVisibility fromDbValue(String value) => switch (value) {
    'only_me' => EventVisibility.onlyMe,
    'specific_faculties' => EventVisibility.specificFaculties,
    'specific_groups' => EventVisibility.specificGroups,
    _ => EventVisibility.everyone,
  };
}
