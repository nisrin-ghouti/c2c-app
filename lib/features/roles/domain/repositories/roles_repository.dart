import '../entities/user_role.dart';

/// The seam between role/permission checks and Supabase. Replaces the old
/// per-boolean `has_role('admin'|'host')` RPC calls that used to live on
/// `HomeRepository` — every feature that needs to know what the current user
/// is allowed to do should go through this instead.
abstract interface class RolesRepository {
  /// All roles held by the current user (student/host/admin — a user can
  /// hold more than one at once).
  Future<Set<UserRole>> myRoles();

  /// Whether the current user is the hardcoded, non-revocable super admin.
  /// Additive on top of [myRoles] — it does not replace the `admin` role,
  /// it unlocks a few extra admin-only actions (e.g. managing other admins)
  /// that a regular admin should not be able to perform on themselves.
  Future<bool> isSuperAdmin();

  /// Whether the current user has been explicitly granted host access to
  /// [eventId] by an admin, without being its original creator.
  Future<bool> hasEventAccess(String eventId);

  /// Whether the current user is eligible for the student-facing app at all
  /// — mirrors `public.is_student_eligible` (the single source of truth also
  /// enforced by matching/points/benefits RPCs server-side): true unless the
  /// account holds admin and/or host with no explicit student grant.
  Future<bool> isStudentEligible();
}
