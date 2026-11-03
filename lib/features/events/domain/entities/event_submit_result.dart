/// Outcome of `create_event_or_program`/`update_event_or_program`/
/// `approve_event`/`reject_event` — all four share the same simple
/// success/forbidden/not-found/unknown shape, so one enum covers them
/// rather than four near-identical ones.
enum EventSubmitResult { ok, forbidden, notFound, unknown }
