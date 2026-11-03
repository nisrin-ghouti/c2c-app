import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../../../main.dart' show supabase;
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/roles_remote_data_source.dart';
import '../../data/repositories/roles_repository_impl.dart';
import '../../domain/entities/user_role.dart';
import '../../domain/repositories/roles_repository.dart';

final _supabaseClientProvider = Provider<SupabaseClient>((ref) => supabase);

final _rolesRemoteDataSourceProvider = Provider<RolesRemoteDataSource>((ref) {
  return RolesRemoteDataSource(ref.watch(_supabaseClientProvider));
});

final rolesRepositoryProvider = Provider<RolesRepository>((ref) {
  return RolesRepositoryImpl(ref.watch(_rolesRemoteDataSourceProvider));
});

/// All roles held by the current user. Replaces the old
/// `HomeRepository.isAdmin()/isHost()` booleans.
final myRolesProvider = FutureProvider<Set<UserRole>>((ref) {
  return ref.watch(rolesRepositoryProvider).myRoles();
});

final isSuperAdminProvider = FutureProvider<bool>((ref) {
  return ref.watch(rolesRepositoryProvider).isSuperAdmin();
});

/// Whether the current user has been granted co-host access to a specific
/// event they didn't create. Not yet consumed anywhere (event management is
/// still Phase B), but the plumbing belongs here alongside the rest of the
/// role system.
final hasEventAccessProvider = FutureProvider.family<bool, String>((
  ref,
  eventId,
) {
  return ref.watch(rolesRepositoryProvider).hasEventAccess(eventId);
});

/// Whether the current user is eligible for the student-facing app —
/// `false` only for an Admin/Host-only account (no explicit student grant).
/// The router uses this as a hard gate; see `appRouterProvider`. Watches
/// `authSessionProvider` (like `profileGateProvider`) so a sign-out/sign-in
/// to a different account on the same device re-evaluates instead of
/// reusing a stale result cached for the previous user. The router's
/// `refreshListenable` builds this eagerly at app start via `ref.listen`,
/// before any session exists, so — again like `profileGateProvider` — it
/// must guard the signed-out case itself rather than assume a caller
/// already checked; there's nothing to gate yet, so it fails open.
final isStudentEligibleProvider = FutureProvider<bool>((ref) {
  ref.watch(authSessionProvider);
  final session = ref.watch(currentAuthSessionProvider);
  if (!session.isAuthenticated) return true;
  return ref.watch(rolesRepositoryProvider).isStudentEligible();
});
