import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_config.dart';
import '../../../../core/error/auth_failure.dart';

/// Thin wrapper around the raw Supabase SDK calls the auth feature needs.
/// This is the *only* file in the feature allowed to reference
/// `supabase_flutter` types directly — [AuthRepositoryImpl] translates
/// everything it returns into domain entities/failures.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);

  final SupabaseClient _client;

  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  /// Fires whenever the password-recovery deep link has been exchanged for a
  /// session (see [AppConfig.passwordResetRedirectUrl]). Filtering on
  /// [AuthChangeEvent] is kept in here rather than the repository so that
  /// type stays out of the rest of the feature.
  Stream<void> get passwordRecoveryEvents => _client.auth.onAuthStateChange
      .where((state) => state.event == AuthChangeEvent.passwordRecovery)
      .map((_) {});

  User? get currentUser => _client.auth.currentUser;

  Future<void> signInWithOtp({
    required String email,
    required bool createUser,
  }) {
    return _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: createUser,
    );
  }

  /// Verifies a 6-digit email code.
  ///
  /// The code's valid `OtpType` depends on which email produced it: a
  /// registration code (the "Confirm signup" template) verifies as
  /// [OtpType.signup], while a "sign in with code" one (the "Magic Link"
  /// template) verifies as [OtpType.email]. One verify screen serves both
  /// flows and can't know which, so try signup first and fall back — passing
  /// the wrong type just errors, it doesn't consume the code.
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) async {
    try {
      return await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      );
    } on AuthException {
      return await _client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> resetPasswordForEmail(String email) {
    return _client.auth.resetPasswordForEmail(
      email,
      redirectTo: AppConfig.passwordResetRedirectUrl,
    );
  }

  Future<void> updatePassword(String newPassword) {
    return _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Invokes the service-role `delete-account` edge function, then clears the
  /// local session. The function authenticates the caller from their own JWT,
  /// so it always deletes the *calling* user and takes no user id argument.
  Future<void> deleteAccount() async {
    final response = await _client.functions.invoke('delete-account');
    if (response.status != 200) {
      final data = response.data;
      final message = data is Map && data['error'] != null
          ? data['error'].toString()
          : 'delete_failed';
      throw UnknownAuthFailure(message);
    }
    await _client.auth.signOut();
  }

  Future<void> ensureMyProfile() => _client.rpc('ensure_my_profile');

  /// Clears a pending account deletion for the signed-in user.
  ///
  /// Takes no argument on purpose: the RPC reads `auth.uid()`, so it can only
  /// ever reactivate the caller's own account. A no-op when nothing is
  /// pending, which is why it is safe to call on every sign-in.
  Future<void> cancelAccountDeletion() =>
      _client.rpc('cancel_account_deletion');

  Future<Map<String, dynamic>> getMyProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select(
          'id, full_name, email, faculty, field_of_study, faculties, '
          'fields_of_study, degree, gender, year, bio, avatar_url, avatar_hue, '
          'hobbies, interests, languages, student_id, banned_at',
        )
        .eq('id', userId)
        .single();
    return row;
  }

  Future<void> updateMyProfile(String userId, Map<String, dynamic> data) {
    return _client.from('profiles').update(data).eq('id', userId);
  }

  /// Uploads a profile picture to the public `avatars` bucket and returns its
  /// public URL. Stored under `<user_id>/…` because the bucket's RLS policies
  /// grant write access by first path segment (see the storage migration).
  ///
  /// `upsert: true` so re-uploading replaces the previous file rather than
  /// accumulating orphans; a cache-busting query param is appended so the new
  /// image actually shows (the URL is otherwise identical).
  Future<String> uploadAvatar(String userId, File file) async {
    final extension = file.path.split('.').last.toLowerCase();
    final path = '$userId/avatar.${extension.isEmpty ? 'jpg' : extension}';

    await _client.storage
        .from('avatars')
        .upload(path, file, fileOptions: const FileOptions(upsert: true));

    final publicUrl = _client.storage.from('avatars').getPublicUrl(path);
    return '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<dynamic> getActivePolicy() => _client.rpc('get_active_policy');

  Future<bool> hasAgreedActivePolicy() async {
    final result = await _client.rpc('has_agreed_active_policy');
    return result as bool? ?? false;
  }

  Future<void> agreeActivePolicy() => _client.rpc('agree_active_policy');
}
