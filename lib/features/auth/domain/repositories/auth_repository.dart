import 'dart:io';

import '../entities/auth_session.dart';
import '../entities/gender.dart';
import '../entities/policy.dart';
import '../entities/profile.dart';

/// The single seam between the auth feature's domain/presentation layers
/// and the outside world (Supabase). Everything above this interface is
/// framework-agnostic and unit-testable with a fake implementation.
abstract interface class AuthRepository {
  /// Emits whenever the auth session changes (sign in, sign out, token
  /// refresh, password recovery, ...).
  Stream<AuthSession> get sessionChanges;

  AuthSession get currentSession;

  /// Emits when the user opens the app via the "reset your password" email
  /// link and Supabase has exchanged it for a (short-lived) recovery
  /// session. The app should navigate to the reset-password screen when
  /// this fires, regardless of where the user currently is.
  Stream<void> get passwordRecoveryEvents;

  /// Sends a one-time 6-digit code to [email]. If [createUser] is false,
  /// the call fails for emails with no existing account (used for "log in
  /// with code" as opposed to sign-up).
  Future<void> sendOtp(String email, {bool createUser = true});

  /// Verifies the code sent by [sendOtp]. Returns true on success.
  Future<bool> verifyOtp({required String email, required String token});

  /// Creates a new account with a password. Supabase requires email
  /// confirmation, so callers should route to OTP verification afterwards.
  Future<void> signUpWithPassword({
    required String email,
    required String password,
    required String fullName,
  });

  /// Signs in with a password. Returns true on success.
  Future<bool> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> sendPasswordResetEmail(String email);

  Future<void> updatePassword(String newPassword);

  Future<void> signOut();

  /// Permanently deletes the signed-in user's account and personal data,
  /// then ends the session. Required by App Store Guideline 5.1.1(v): an app
  /// that lets users create an account must let them delete it from inside
  /// the app.
  ///
  /// The client cannot remove its own `auth.users` row, so this delegates to
  /// the `delete-account` edge function, which runs with the service-role
  /// key and verifies the caller's own JWT before deleting.
  Future<void> deleteAccount();

  /// Idempotently ensures a `profiles` row exists for the current user.
  Future<void> ensureProfileExists();

  /// Cancels a pending account deletion for the signed-in user, reactivating
  /// the account. A no-op when no deletion is pending.
  Future<void> cancelAccountDeletion();

  Future<Profile> getMyProfile();

  /// Uploads [file] as the current user's profile picture and returns the
  /// public URL to store on the profile.
  Future<String> uploadAvatar(File file);

  Future<void> saveProfile({
    required String fullName,
    List<String>? faculties,
    List<String>? fieldsOfStudy,
    String? degree,
    Gender? gender,
    int? year,
    String? bio,
    List<String>? hobbies,
    List<String>? interests,
    List<String>? languages,
    String? avatarUrl,

    /// When true, explicitly nulls the stored avatar. Needed because a plain
    /// null `avatarUrl` means "leave unchanged", not "remove".
    bool clearAvatar,
  });

  Future<Policy?> getActivePolicy();

  Future<bool> hasAgreedActivePolicy();

  Future<void> agreeToActivePolicy();
}
