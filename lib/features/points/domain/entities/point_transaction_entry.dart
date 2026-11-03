/// One row of the points ledger (`point_transactions`), as shown in the
/// "points history" list. `reason` is the raw ledger value (e.g.
/// `event_attendance`, `meeting_first`) — the presentation layer maps it to
/// a localized label so this entity stays framework/locale agnostic.
class PointTransactionEntry {
  const PointTransactionEntry({
    required this.id,
    required this.amount,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final int amount;
  final String reason;
  final DateTime createdAt;
}
