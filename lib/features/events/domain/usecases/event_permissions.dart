import '../../../roles/domain/entities/user_role.dart';
import '../entities/campus_event.dart';

/// Pure permission rule, replacing the old `HomeDashboard.canManage`. Kept
/// framework-free (no repository/provider dependency) so it's trivial to
/// unit test.
abstract final class EventPermissions {
  /// Whether the viewer may manage (edit/delete/view registrants for)
  /// [event] — admins manage everything; hosts manage events they created
  /// or were explicitly granted co-host access to.
  static bool canManage(
    CampusEvent event, {
    required Set<UserRole> roles,
    required String viewerId,
    required bool hasHostAccessGrant,
  }) {
    if (roles.contains(UserRole.admin)) return true;
    if (!roles.contains(UserRole.host)) return false;
    return event.createdBy == viewerId || hasHostAccessGrant;
  }
}
