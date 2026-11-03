import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/auth_failure.dart';
import '../../domain/entities/policy.dart';
import '../../domain/usecases/policy_usecases.dart';
import '../providers/auth_providers.dart';
import 'auth_action_state.dart';
import 'auth_message_kind.dart';

class PolicyPageData {
  const PolicyPageData({required this.policy, required this.alreadyAgreed});

  final Policy? policy;
  final bool alreadyAgreed;
}

/// One-shot load of "what's the active policy, and has this user already
/// agreed to it" — a plain [FutureProvider] since it's pure data fetching,
/// no imperative action involved.
final policyPageDataProvider = FutureProvider.autoDispose<PolicyPageData>((
  ref,
) async {
  final getActivePolicy = ref.watch(getActivePolicyProvider);
  final hasAgreed = ref.watch(hasAgreedActivePolicyProvider);
  final results = await Future.wait([getActivePolicy(), hasAgreed()]);
  return PolicyPageData(
    policy: results[0] as Policy?,
    alreadyAgreed: results[1] as bool,
  );
});

class AgreeToPolicyController extends StateNotifier<AuthActionState> {
  AgreeToPolicyController(this._agreeToActivePolicy)
    : super(AuthActionState.initial);

  final AgreeToActivePolicy _agreeToActivePolicy;

  Future<bool> agree() async {
    state = state.loadingStarted();
    try {
      await _agreeToActivePolicy();
      state = AuthActionState.success;
      return true;
    } on AuthFailure catch (e) {
      state = state.withError(classifyAuthFailure(e));
      return false;
    }
  }
}

final agreeToPolicyControllerProvider =
    StateNotifierProvider.autoDispose<AgreeToPolicyController, AuthActionState>(
      (ref) {
        return AgreeToPolicyController(ref.watch(agreeToActivePolicyProvider));
      },
    );
