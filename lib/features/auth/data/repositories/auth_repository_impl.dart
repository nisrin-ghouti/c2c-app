import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException, StorageException;

import '../../../../core/error/auth_failure.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/gender.dart';
import '../../domain/entities/policy.dart';
import '../../domain/entities/profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  AuthSession _toSession() {
    final user = _remote.currentUser;
    if (user == null) return const AuthSession.signedOut();
    return AuthSession(userId: user.id, userEmail: user.email);
  }

  @override
  Stream<AuthSession> get sessionChanges =>
      _remote.onAuthStateChange.map((_) => _toSession());

  @override
  AuthSession get currentSession => _toSession();

  @override
  Stream<void> get passwordRecoveryEvents => _remote.passwordRecoveryEvents;

  @override
  Future<void> sendOtp(String email, {bool createUser = true}) async {
    try {
      await _remote.signInWithOtp(email: email, createUser: createUser);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<bool> verifyOtp({required String email, required String token}) async {
    try {
      final response = await _remote.verifyOtp(email: email, token: token);
      return response.session != null;
    } on AuthException catch (_) {
      throw const InvalidOtpFailure();
    }
  }

  @override
  Future<void> signUpWithPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      await _remote.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<bool> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remote.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null) return false;

      final profile = await getMyProfile();

      if (profile.isBanned) {
        await _remote.signOut();
        throw const BlockedUserFailure();
      }

      return true;
    } on BlockedUserFailure {
      rethrow;
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _remote.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _remote.updatePassword(newPassword);
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  @override
  Future<void> signOut() => _remote.signOut();

  @override
  Future<void> deleteAccount() => _remote.deleteAccount();

  @override
  Future<void> cancelAccountDeletion() async {
    try {
      await _remote.cancelAccountDeletion();
    } on PostgrestException catch (e) {
      throw UnknownAuthFailure(e.message);
    }
  }

  @override
  Future<void> ensureProfileExists() async {
    try {
      await _remote.ensureMyProfile();
    } on PostgrestException catch (e) {
      throw UnknownAuthFailure(e.message);
    }
  }

  @override
  Future<Profile> getMyProfile() async {
    final user = _remote.currentUser;
    if (user == null) throw const UnknownAuthFailure('Not signed in');

    try {
      final row = await _remote.getMyProfile(user.id);
      return Profile(
        id: row['id'] as String,
        fullName: (row['full_name'] as String?) ?? '',
        email: row['email'] as String?,
        // Prefer the new array columns; fall back to the legacy single columns
        // for rows saved before the multi-value migration ran.
        faculties: _multiValue(row['faculties'], row['faculty']),
        fieldsOfStudy: _multiValue(
          row['fields_of_study'],
          row['field_of_study'],
        ),
        degree: row['degree'] as String?,
        gender: Gender.fromDbValue(row['gender'] as String?),
        year: row['year'] as int?,
        bio: row['bio'] as String?,
        avatarUrl: row['avatar_url'] as String?,
        studentId: row['student_id'] as String?,
        avatarHue: (row['avatar_hue'] as int?) ?? 220,
        hobbies: _stringList(row['hobbies']),
        interests: _stringList(row['interests']),
        languages: _stringList(row['languages']),
        bannedAt: row['banned_at'] == null
            ? null
            : DateTime.parse(row['banned_at'] as String),
      );
    } on PostgrestException catch (e) {
      throw UnknownAuthFailure(e.message);
    }
  }

  @override
  Future<String> uploadAvatar(File file) async {
    final user = _remote.currentUser;
    if (user == null) throw const UnknownAuthFailure('Not signed in');
    try {
      return await _remote.uploadAvatar(user.id, file);
    } on StorageException catch (e) {
      throw UnknownAuthFailure(e.message);
    } on PostgrestException catch (e) {
      throw UnknownAuthFailure(e.message);
    }
  }

  List<String> _stringList(dynamic value) =>
      (value as List?)?.cast<String>() ?? const [];

  /// Reads the new `text[]` column, falling back to a single legacy column
  /// (wrapped in a one-element list) when the array is absent/empty.
  List<String> _multiValue(dynamic arrayValue, dynamic legacyValue) {
    final array = _stringList(
      arrayValue,
    ).where((v) => v.trim().isNotEmpty).toList();
    if (array.isNotEmpty) return array;
    final legacy = legacyValue as String?;
    return (legacy != null && legacy.trim().isNotEmpty) ? [legacy] : const [];
  }

  @override
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
    bool clearAvatar = false,
  }) async {
    final user = _remote.currentUser;
    if (user == null) throw const UnknownAuthFailure('Not signed in');

    try {
      await _remote.updateMyProfile(user.id, {
        'full_name': fullName,
        // Store the full multi-value lists, and mirror the first entry into the
        // legacy single columns so Matches filtering / candidate cards / home
        // previews (which still read the single columns) keep working.
        if (faculties != null) ...{
          'faculties': faculties,
          'faculty': faculties.isEmpty ? null : faculties.first,
        },
        if (fieldsOfStudy != null) ...{
          'fields_of_study': fieldsOfStudy,
          'field_of_study': fieldsOfStudy.isEmpty ? null : fieldsOfStudy.first,
        },
        'degree': ?degree,
        if (gender != null) 'gender': gender.dbValue,
        'year': ?year,
        'bio': ?bio,
        'hobbies': ?hobbies,
        'interests': ?interests,
        'languages': ?languages,
        // clearAvatar wins: it writes an explicit null to remove the photo,
        // whereas a null avatarUrl (via the ?-entry) just leaves it unchanged.
        if (clearAvatar) 'avatar_url': null else 'avatar_url': ?avatarUrl,
      });
    } on PostgrestException catch (e) {
      throw UnknownAuthFailure(e.message);
    }
  }

  @override
  Future<Policy?> getActivePolicy() async {
    try {
      final result = await _remote.getActivePolicy();
      if (result == null) return null;
      final map = Map<String, dynamic>.from(result as Map);
      return Policy(
        id: map['id'] as String,
        title: map['title'] as String,
        body: map['body'] as String,
        version: map['version'] as int,
      );
    } on PostgrestException catch (e) {
      throw UnknownAuthFailure(e.message);
    }
  }

  @override
  Future<bool> hasAgreedActivePolicy() async {
    try {
      return await _remote.hasAgreedActivePolicy();
    } on PostgrestException catch (e) {
      throw UnknownAuthFailure(e.message);
    }
  }

  @override
  Future<void> agreeToActivePolicy() async {
    try {
      await _remote.agreeActivePolicy();
    } on PostgrestException catch (e) {
      throw UnknownAuthFailure(e.message);
    }
  }

  AuthFailure _mapAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid')) return InvalidCredentialsFailure(e.message);
    if (msg.contains('confirm')) return EmailNotConfirmedFailure(e.message);
    if (msg.contains('registered') || msg.contains('exists')) {
      return UserAlreadyExistsFailure(e.message);
    }
    if (msg.contains('not')) return UserNotFoundFailure(e.message);
    return UnknownAuthFailure(e.message);
  }
}
