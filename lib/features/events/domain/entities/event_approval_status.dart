/// Where an event/program is in the host-submits → admin-approves workflow.
/// Only `approved` events are ever visible to students — see
/// `EventsRemoteDataSource.getUpcomingEvents` for the server-side gate.
enum EventApprovalStatus {
  pending,
  approved,
  rejected;

  String get dbValue => switch (this) {
    EventApprovalStatus.pending => 'pending',
    EventApprovalStatus.approved => 'approved',
    EventApprovalStatus.rejected => 'rejected',
  };

  static EventApprovalStatus fromDbValue(String value) => switch (value) {
    'approved' => EventApprovalStatus.approved,
    'rejected' => EventApprovalStatus.rejected,
    _ => EventApprovalStatus.pending,
  };
}
