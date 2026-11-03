import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/auth_failure.dart';
import '../../domain/usecases/auth_usecases.dart';
import '../providers/auth_providers.dart';
import 'auth_action_state.dart';
import 'auth_message_kind.dart';

class ResetPasswordController extends StateNotifier<AuthActionState> {
  ResetPasswordController(this._updatePassword)
    : super(AuthActionState.initial);

  final UpdatePassword _updatePassword;

  Future<bool> submit(String newPassword) async {
    state = state.loadingStarted();
    try {
      await _updatePassword(newPassword);
      state = state.withInfo(AuthInfoKind.passwordUpdated);
      return true;
    } on AuthFailure catch (e) {
      state = state.withError(classifyAuthFailure(e));
      return false;
    }
  }
}

final resetPasswordControllerProvider =
    StateNotifierProvider.autoDispose<ResetPasswordController, AuthActionState>(
      (ref) {
        return ResetPasswordController(ref.watch(updatePasswordProvider));
      },
    );
