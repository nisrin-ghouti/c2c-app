import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../../../main.dart' show supabase;
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../domain/usecases/determine_post_auth_destination.dart';
import '../../domain/usecases/policy_usecases.dart';
import '../../domain/usecases/profile_usecases.dart';

/// --- Wiring (composition root for the auth feature) -----------------
///
/// Each layer only ever depends on the one below it via these providers:
/// screens -> controllers -> use cases -> repository -> data source.

final _supabaseClientProvider = Provider<SupabaseClient>((ref) => supabase);

final _authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(_supabaseClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(_authRemoteDataSourceProvider));
});

// --- Use cases -----------------------------------------------------------

final sendOtpProvider = Provider(
  (ref) => SendOtp(ref.watch(authRepositoryProvider)),
);
final verifyOtpProvider = Provider(
  (ref) => VerifyOtp(ref.watch(authRepositoryProvider)),
);
final signUpWithPasswordProvider = Provider(
  (ref) => SignUpWithPassword(ref.watch(authRepositoryProvider)),
);
final signInWithPasswordProvider = Provider(
  (ref) => SignInWithPassword(ref.watch(authRepositoryProvider)),
);
final sendPasswordResetEmailProvider = Provider(
  (ref) => SendPasswordResetEmail(ref.watch(authRepositoryProvider)),
);
final updatePasswordProvider = Provider(
  (ref) => UpdatePassword(ref.watch(authRepositoryProvider)),
);
final signOutProvider = Provider(
  (ref) => SignOut(ref.watch(authRepositoryProvider)),
);
final deleteAccountProvider = Provider(
  (ref) => DeleteAccount(ref.watch(authRepositoryProvider)),
);
/// Whether the signed-in user has been blocked by an admin, live.
///
/// `ref.watch(authSessionProvider)` is load-bearing: without it this read
/// `currentUser` exactly once, when the provider was first built. `C2CApp`
/// builds it on the first frame — before anyone has signed in — so the
/// provider latched onto `Stream.value(false)` and stayed there for the whole
/// session. Anyone who signed in afterwards had no ban detection at all.
///
/// Requires `profiles` in the `supabase_realtime` publication (migration
/// 0089). Without it the subscription connects, reports healthy, and only
/// ever delivers its initial fetch — so a block landed while the app was open
/// was invisible until the process was killed, which is precisely what was
/// reported. The server-side half (`auth.users.banned_until`, also 0089) is
/// what actually enforces the block; this is how the open app finds out.
final currentUserBanProvider = StreamProvider<bool>((ref) {
  ref.watch(authSessionProvider);
  final client = ref.watch(_supabaseClientProvider);
  final userId = client.auth.currentUser?.id;

  if (userId == null) {
    return Stream.value(false);
  }

  return client
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('id', userId)
      .map((rows) => rows.isNotEmpty && rows.first['banned_at'] != null);
});
final ensureProfileExistsProvider = Provider(
  (ref) => EnsureProfileExists(ref.watch(authRepositoryProvider)),
);
final getMyProfileProvider = Provider(
  (ref) => GetMyProfile(ref.watch(authRepositoryProvider)),
);
final saveProfileProvider = Provider(
  (ref) => SaveProfile(ref.watch(authRepositoryProvider)),
);
final uploadAvatarProvider = Provider(
  (ref) => UploadAvatar(ref.watch(authRepositoryProvider)),
);

final getActivePolicyProvider = Provider(
  (ref) => GetActivePolicy(ref.watch(authRepositoryProvider)),
);
final hasAgreedActivePolicyProvider = Provider(
  (ref) => HasAgreedActivePolicy(ref.watch(authRepositoryProvider)),
);
final agreeToActivePolicyProvider = Provider(
  (ref) => AgreeToActivePolicy(ref.watch(authRepositoryProvider)),
);

final determinePostAuthDestinationProvider = Provider(
  (ref) => DeterminePostAuthDestination(ref.watch(authRepositoryProvider)),
);

final watchPasswordRecoveryEventsProvider = Provider(
  (ref) => WatchPasswordRecoveryEvents(ref.watch(authRepositoryProvider)),
);

// --- Session state ---------------------------------------------------------

/// Live auth session stream — the router watches this to decide whether the
/// user may see authenticated routes.
final authSessionProvider = StreamProvider<AuthSession>((ref) {
  return ref.watch(authRepositoryProvider).sessionChanges;
});

/// Synchronous snapshot of the current session (no async gap), handy inside
/// redirect callbacks which can't `await` a stream.
final currentAuthSessionProvider = Provider<AuthSession>((ref) {
  ref.watch(authSessionProvider); // re-evaluate on every session change
  return ref.watch(authRepositoryProvider).currentSession;
});

/// The app root (`C2CApp`) listens to this to force-navigate to the
/// reset-password screen whenever the user opens the app via the "reset
/// your password" email link — see `AppConfig.passwordResetRedirectUrl`.
final passwordRecoveryEventsProvider = StreamProvider<void>((ref) {
  return ref.watch(watchPasswordRecoveryEventsProvider)();
});

// --- Mandatory-completion gate --------------------------------------------

/// Whether the signed-in user has satisfied the two account-level gates that
/// stand between sign-in and the main app: a complete profile (name + at least
/// one field of study) and agreement to the active policy.
class ProfileGate {
  const ProfileGate({
    required this.profileComplete,
    required this.policyAgreed,
  });

  final bool profileComplete;
  final bool policyAgreed;
}

/// Loads the completion/policy status for the current user so the router can
/// *hard-gate* the app — an incomplete profile can never reach a main tab,
/// even on a cold start with a restored session (which bypasses the imperative
/// post-auth navigation). Returns null when signed out.
///
/// Invalidate this after saving the profile or agreeing to the policy so the
/// router re-evaluates and lets the user advance.
final profileGateProvider = FutureProvider<ProfileGate?>((ref) async {
  ref.watch(authSessionProvider); // re-run whenever the session changes
  final session = ref.watch(currentAuthSessionProvider);
  if (!session.isAuthenticated) return null;

  final repo = ref.watch(authRepositoryProvider);
  await repo.ensureProfileExists();
  final profile = await repo.getMyProfile();
  final agreed = await repo.hasAgreedActivePolicy();
  return ProfileGate(profileComplete: profile.isComplete, policyAgreed: agreed);
});
