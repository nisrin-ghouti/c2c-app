import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/benefit.dart';
import '../../domain/entities/benefit_submit_result.dart';
import '../providers/benefits_providers.dart';

/// Backs the admin benefits editor — mirrors `EventApprovalController`
/// (re-fetch-on-mutate convention).
class BenefitsAdminController extends StateNotifier<AsyncValue<List<Benefit>>> {
  BenefitsAdminController(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _ref.read(adminListBenefitsProvider)(),
    );
  }

  Future<void> refresh() => _load();

  Future<BenefitSubmitResult> create({
    required String title,
    String? description,
    String? category,
    required int pointCost,
    String? imageUrl,
    String? partnerBusinessName,
    String? businessDescription,
    String? howToRedeem,
    String? externalLink,
    String? location,
    String? mapsLink,
  }) async {
    final result = await _ref.read(createBenefitProvider)(
      title: title,
      description: description,
      category: category,
      pointCost: pointCost,
      imageUrl: imageUrl,
      partnerBusinessName: partnerBusinessName,
      businessDescription: businessDescription,
      howToRedeem: howToRedeem,
      externalLink: externalLink,
      location: location,
      mapsLink: mapsLink,
    );
    if (result == BenefitSubmitResult.ok) {
      await _load();
      _ref.invalidate(benefitsCatalogProvider);
    }
    return result;
  }

  Future<BenefitSubmitResult> update({
    required String id,
    required String title,
    String? description,
    String? category,
    required int pointCost,
    String? imageUrl,
    String? partnerBusinessName,
    String? businessDescription,
    String? howToRedeem,
    String? externalLink,
    String? location,
    String? mapsLink,
  }) async {
    final result = await _ref.read(updateBenefitProvider)(
      id: id,
      title: title,
      description: description,
      category: category,
      pointCost: pointCost,
      imageUrl: imageUrl,
      partnerBusinessName: partnerBusinessName,
      businessDescription: businessDescription,
      howToRedeem: howToRedeem,
      externalLink: externalLink,
      location: location,
      mapsLink: mapsLink,
    );
    if (result == BenefitSubmitResult.ok) {
      await _load();
      _ref.invalidate(benefitsCatalogProvider);
    }
    return result;
  }

  Future<BenefitSubmitResult> setActive(String id, bool active) async {
    final result = await _ref.read(setBenefitActiveProvider)(id, active);
    if (result == BenefitSubmitResult.ok) {
      await _load();
      _ref.invalidate(benefitsCatalogProvider);
    }
    return result;
  }
}

final benefitsAdminControllerProvider =
    StateNotifierProvider.autoDispose<
      BenefitsAdminController,
      AsyncValue<List<Benefit>>
    >((ref) {
      return BenefitsAdminController(ref);
    });
