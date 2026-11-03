/// A framework-agnostic view of "are we logged in, and as whom" — the
/// domain layer's replacement for Supabase's `User`/`AuthState`, so nothing
/// above the repository boundary needs to import `supabase_flutter`.
class AuthSession {
  const AuthSession({required this.userId, required this.userEmail});

  const AuthSession.signedOut() : userId = null, userEmail = null;

  final String? userId;
  final String? userEmail;

  bool get isAuthenticated => userId != null;
}
