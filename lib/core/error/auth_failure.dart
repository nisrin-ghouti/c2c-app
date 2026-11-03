/// Domain-level auth failures. The data layer is responsible for translating
/// Supabase's `AuthException`/`PostgrestException` messages into these —
/// nothing above the repository boundary should know Supabase exists.
sealed class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;
}

/// Wrong email/password combination.
class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure([super.message = 'Invalid credentials']);
}

/// The account exists but the email hasn't been confirmed/verified yet.
class EmailNotConfirmedFailure extends AuthFailure {
  const EmailNotConfirmedFailure([super.message = 'Email not confirmed']);
}

/// Sign-up attempted with an email that's already registered.
class UserAlreadyExistsFailure extends AuthFailure {
  const UserAlreadyExistsFailure([super.message = 'User already exists']);
}

/// OTP sign-in requested for an email with no account.
class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure([super.message = 'User not found']);
}

/// The submitted OTP code was wrong or expired.
class InvalidOtpFailure extends AuthFailure {
  const InvalidOtpFailure([super.message = 'Invalid or expired code']);
}

/// The account has been blocked by C2C management.
class BlockedUserFailure extends AuthFailure {
  const BlockedUserFailure([super.message = 'User is blocked']);
}

/// Catch-all for anything not specifically classified above.
class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure(super.message);
}
