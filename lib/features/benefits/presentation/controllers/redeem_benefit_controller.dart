import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/presentation/controllers/home_controller.dart';
import '../../domain/entities/redeem_result.dart';
import '../providers/benefits_providers.dart';

class RedeemBenefitController extends StateNotifier<AsyncValue<void>> {
  RedeemBenefitController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<RedeemBenefitOutcome> redeem(String benefitId) async {
    state = const AsyncLoading();
    final outcome = await _ref.read(redeemBenefitProvider)(benefitId);
    state = const AsyncData(null);
    if (outcome.result == RedeemBenefitResult.ok) {
      _ref.invalidate(homeDashboardProvider);
      _ref.invalidate(myDigitalCardsProvider);
    }
    return outcome;
  }
}

final redeemBenefitControllerProvider =
    StateNotifierProvider.autoDispose<
      RedeemBenefitController,
      AsyncValue<void>
    >((ref) {
      return RedeemBenefitController(ref);
    });
