import '../repositories/auth_repository.dart';

/// Where to send the user immediately after a successful sign-in/sign-up.
enum PostAuthDestination { completeProfile, policy, home }

/// Business rule shared by every entry point into the app (OTP verify,
/// password login, password reset): a user must have a name on file and
/// must have agreed to the active policy before they can reach Home.
class DeterminePostAuthDestination {
  const DeterminePostAuthDestination(this._repository);
  final AuthRepository _repository;

  Future<PostAuthDestination> call() async {
    // Signing in is how a pending account deletion is cancelled (migration
    // 0088). This runs on every successful sign-in and is a no-op when
    // nothing is pending, so it needs no "is it pending?" round trip first.
    //
    // Before `ensureProfileExists`, deliberately: a deactivated account still
    // has its profile, and reactivating first means the rest of this method —
    // and everything after it — sees a live account rather than a
    // soft-deleted one.
    //
    // A failure here must not block sign-in. The worst case is that the
    // account stays pending and the user can try again by signing in once
    // more, which is strictly better than being locked out by a failed
    // reactivation.
    try {
      await _repository.cancelAccountDeletion();
    } catch (_) {}

    await _repository.ensureProfileExists();

    final profile = await _repository.getMyProfile();
    if (!profile.isComplete) return PostAuthDestination.completeProfile;

    final agreed = await _repository.hasAgreedActivePolicy();
    if (!agreed) return PostAuthDestination.policy;

    return PostAuthDestination.home;
  }
}
