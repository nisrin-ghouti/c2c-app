import 'auth_message_kind.dart';

/// Shared UI state shape for every auth-flow controller: are we mid-request,
/// and is there an error/info banner to show.
class AuthActionState {
  const AuthActionState({this.loading = false, this.errorKind, this.infoKind});

  final bool loading;
  final AuthErrorKind? errorKind;
  final AuthInfoKind? infoKind;

  static const initial = AuthActionState();

  AuthActionState loadingStarted() => const AuthActionState(loading: true);

  AuthActionState withError(AuthErrorKind kind) {
    return AuthActionState(errorKind: kind);
  }

  AuthActionState withInfo(AuthInfoKind kind) {
    return AuthActionState(infoKind: kind);
  }

  static const success = AuthActionState();
}
