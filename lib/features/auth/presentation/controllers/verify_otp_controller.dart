import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/auth_failure.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../../domain/usecases/determine_post_auth_destination.dart';
import '../providers/auth_providers.dart';
import 'auth_action_state.dart';
import 'auth_message_kind.dart';

class VerifyOtpController extends StateNotifier<AuthActionState> {
  VerifyOtpController({
    required VerifyOtp verifyOtp,
    required SendOtp sendOtp,
    required DeterminePostAuthDestination determinePostAuthDestination,
  }) : _verifyOtp = verifyOtp,
       _sendOtp = sendOtp,
       _determinePostAuthDestination = determinePostAuthDestination,
       super(AuthActionState.initial);

  final VerifyOtp _verifyOtp;
  final SendOtp _sendOtp;
  final DeterminePostAuthDestination _determinePostAuthDestination;

  Future<PostAuthDestination?> verify({
    required String email,
    required String token,
  }) async {
    state = state.loadingStarted();
    try {
      final ok = await _verifyOtp(email: email, token: token);
      if (!ok) {
        state = state.withError(AuthErrorKind.invalidOtp);
        return null;
      }
      final destination = await _determinePostAuthDestination();
      state = AuthActionState.success;
      return destination;
    } on AuthFailure catch (e) {
      state = state.withError(classifyAuthFailure(e));
      return null;
    }
  }

  /// Returns whether a new code was actually sent, so the caller can start the
  /// resend cooldown only on success (a failed send shouldn't lock the button).
  Future<bool> resend(String email) async {
    state = state.loadingStarted();
    try {
      await _sendOtp(email, createUser: false);
      state = state.withInfo(AuthInfoKind.otpResent);
      return true;
    } on AuthFailure catch (e) {
      state = state.withError(classifyAuthFailure(e));
      return false;
    }
  }
}

final verifyOtpControllerProvider =
    StateNotifierProvider.autoDispose<VerifyOtpController, AuthActionState>((
      ref,
    ) {
      return VerifyOtpController(
        verifyOtp: ref.watch(verifyOtpProvider),
        sendOtp: ref.watch(sendOtpProvider),
        determinePostAuthDestination: ref.watch(
          determinePostAuthDestinationProvider,
        ),
      );
    });
