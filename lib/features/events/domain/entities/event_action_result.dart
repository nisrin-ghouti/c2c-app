/// Outcome of `register_for_event`, mapped from the RPC's `status` field.
enum EventActionResult {
  ok,
  alreadyRegistered,
  full,
  ended,
  notPublished,
  notFound,
  unknown,
}
