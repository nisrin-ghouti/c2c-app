/// Outcome of `cancel_event_registration`, mapped from the RPC's `status`
/// field. Kept separate from [EventActionResult] since cancel and register
/// have different failure modes (the event already started vs. never
/// having registered, neither of which register-for-event needs).
enum EventCancelResult { ok, notRegistered, alreadyStarted, unknown }
