import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/auth_failure.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../providers/auth_providers.dart';
import 'auth_action_state.dart';
import 'auth_message_kind.dart';

class ForgotPasswordController extends StateNotifier<AuthActionState> {
  ForgotPasswordController(this._sendPasswordResetEmail)
    : super(AuthActionState.initial);

  final SendPasswordResetEmail _sendPasswordResetEmail;

  Future<void> submit(String email) async {
    state = state.loadingStarted();
    try {
      await _sendPasswordResetEmail(email);
      state = state.withInfo(AuthInfoKind.resetLinkSent);
    } on AuthFailure catch (e) {
      state = state.withError(classifyAuthFailure(e));
    }
  }
}

final forgotPasswordControllerProvider =
    StateNotifierProvider.autoDispose<
      ForgotPasswordController,
      AuthActionState
    >((ref) {
      return ForgotPasswordController(
        ref.watch(sendPasswordResetEmailProvider),
      );
    });
