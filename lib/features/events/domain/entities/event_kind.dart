/// A one-time event (`single`) vs. a multi-session `program`. Programs get
/// their own sessions table and a points-equation summary — see Phase B
/// Slice 4 of the expansion plan; this enum exists from Slice 1 onward so
/// the event-type filter and entity shape don't need revisiting later.
enum EventKind {
  single,
  program;

  String get dbValue => switch (this) {
    EventKind.single => 'single',
    EventKind.program => 'program',
  };

  static EventKind fromDbValue(String value) => switch (value) {
    'program' => EventKind.program,
    _ => EventKind.single,
  };
}
