import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Thin, single-purpose wrappers around [AuthRepository] — the "use case"
/// layer of clean architecture. They exist so controllers depend on named,
/// intention-revealing operations instead of poking a fat repository
/// directly, and so each operation is trivially mockable in isolation.

class SendOtp {
  const SendOtp(this._repository);
  final AuthRepository _repository;

  Future<void> call(String email, {bool createUser = true}) {
    return _repository.sendOtp(email, createUser: createUser);
  }
}

class VerifyOtp {
  const VerifyOtp(this._repository);
  final AuthRepository _repository;

  Future<bool> call({required String email, required String token}) {
    return _repository.verifyOtp(email: email, token: token);
  }
}

class SignUpWithPassword {
  const SignUpWithPassword(this._repository);
  final AuthRepository _repository;

  Future<void> call({
    required String email,
    required String password,
    required String fullName,
  }) {
    return _repository.signUpWithPassword(
      email: email,
      password: password,
      fullName: fullName,
    );
  }
}

class SignInWithPassword {
  const SignInWithPassword(this._repository);
  final AuthRepository _repository;

  Future<bool> call({required String email, required String password}) {
    return _repository.signInWithPassword(email: email, password: password);
  }
}

class SendPasswordResetEmail {
  const SendPasswordResetEmail(this._repository);
  final AuthRepository _repository;

  Future<void> call(String email) => _repository.sendPasswordResetEmail(email);
}

class UpdatePassword {
  const UpdatePassword(this._repository);
  final AuthRepository _repository;

  Future<void> call(String newPassword) =>
      _repository.updatePassword(newPassword);
}

class SignOut {
  const SignOut(this._repository);
  final AuthRepository _repository;

  Future<void> call() => _repository.signOut();
}

/// Permanently deletes the signed-in user's account (App Store 5.1.1(v)).
class DeleteAccount {
  const DeleteAccount(this._repository);
  final AuthRepository _repository;

  Future<void> call() => _repository.deleteAccount();
}

class WatchSessionChanges {
  const WatchSessionChanges(this._repository);
  final AuthRepository _repository;

  Stream<AuthSession> call() => _repository.sessionChanges;
}

class GetCurrentSession {
  const GetCurrentSession(this._repository);
  final AuthRepository _repository;

  AuthSession call() => _repository.currentSession;
}

class WatchPasswordRecoveryEvents {
  const WatchPasswordRecoveryEvents(this._repository);
  final AuthRepository _repository;

  Stream<void> call() => _repository.passwordRecoveryEvents;
}
