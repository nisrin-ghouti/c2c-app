/// A permission a user account can hold. A single user may hold more than
/// one simultaneously (e.g. a host who is also a student) — see
/// `RolesRepository.myRoles()`, which returns a `Set<UserRole>` rather than
/// a single value.
enum UserRole { student, host, admin }
