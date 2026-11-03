import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/auth_failure.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../domain/usecases/determine_post_auth_destination.dart';
import '../providers/auth_providers.dart';
import 'auth_action_state.dart';
import 'auth_message_kind.dart';

enum AuthMode { login, signup }

enum LoginMethod { password, otp }

/// What the screen should do once a submission finishes successfully.
sealed class AuthSubmitOutcome {
  const AuthSubmitOutcome();
}

class NavigateToVerify extends AuthSubmitOutcome {
  const NavigateToVerify(this.email);
  final String email;
}

class NavigateToDestination extends AuthSubmitOutcome {
  const NavigateToDestination(this.destination);
  final PostAuthDestination destination;
}

class AuthFormController extends StateNotifier<AuthActionState> {
  AuthFormController({
    required SignInWithPassword signInWithPassword,
    required SignUpWithPassword signUpWithPassword,
    required SendOtp sendOtp,
    required DeterminePostAuthDestination determinePostAuthDestination,
  }) : _signInWithPassword = signInWithPassword,
       _signUpWithPassword = signUpWithPassword,
       _sendOtp = sendOtp,
       _determinePostAuthDestination = determinePostAuthDestination,
       super(AuthActionState.initial);

  final SignInWithPassword _signInWithPassword;
  final SignUpWithPassword _signUpWithPassword;
  final SendOtp _sendOtp;
  final DeterminePostAuthDestination _determinePostAuthDestination;

  Future<AuthSubmitOutcome?> submitLogin({
    required String email,
    required String password,
    required LoginMethod method,
  }) async {
    state = state.loadingStarted();

    if (method == LoginMethod.otp) {
      try {
        await _sendOtp(email, createUser: false);
        if (!mounted) return null;
        state = AuthActionState.success;
        return NavigateToVerify(email);
      } on AuthFailure catch (e) {
        if (!mounted) return null;
        state = state.withError(classifyAuthFailure(e));
        return null;
      }
    }

    try {
      final ok = await _signInWithPassword(email: email, password: password);
      if (!mounted) return null;
      if (!ok) {
        state = state.withError(AuthErrorKind.generic);
        return null;
      }
      final destination = await _determinePostAuthDestination();
      // A successful sign-in flips the auth session, which can trigger the
      // router's redirect and dispose this (autoDispose) controller before we
      // get here — touching `state` afterwards would throw. Bail out quietly;
      // the router's gate handles navigation from here.
      if (!mounted) return null;
      state = AuthActionState.success;
      return NavigateToDestination(destination);
    } on EmailNotConfirmedFailure {
      if (!mounted) return null;
      state = state.withError(AuthErrorKind.emailNotConfirmed);
      // Mirror the reference app: bounce straight to OTP verification.
      try {
        await _sendOtp(email, createUser: false);
      } on AuthFailure {
        // Best-effort — the user can still hit "resend" on the verify screen.
      }
      return NavigateToVerify(email);
    } on AuthFailure catch (e) {
      if (!mounted) return null;
      state = state.withError(classifyAuthFailure(e));
      return null;
    }
  }

  Future<AuthSubmitOutcome?> submitSignup({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = state.loadingStarted();
    try {
      await _signUpWithPassword(
        email: email,
        password: password,
        fullName: fullName,
      );
      if (!mounted) return null;
      state = AuthActionState.success;
      return NavigateToVerify(email);
    } on AuthFailure catch (e) {
      if (!mounted) return null;
      state = state.withError(classifyAuthFailure(e));
      return null;
    }
  }
}

final authFormControllerProvider =
    StateNotifierProvider.autoDispose<AuthFormController, AuthActionState>((
      ref,
    ) {
      return AuthFormController(
        signInWithPassword: ref.watch(signInWithPasswordProvider),
        signUpWithPassword: ref.watch(signUpWithPasswordProvider),
        sendOtp: ref.watch(sendOtpProvider),
        determinePostAuthDestination: ref.watch(
          determinePostAuthDestinationProvider,
        ),
      );
    });
