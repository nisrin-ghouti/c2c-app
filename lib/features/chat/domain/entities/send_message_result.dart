/// Outcome of `send_message` — `blocked` covers both directions (either
/// side blocked the other), the RPC doesn't distinguish which.
enum SendMessageResult { ok, blocked, empty, forbidden, unknown }
