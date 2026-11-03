import 'dart:io';

import '../entities/benefit.dart';
import '../entities/benefit_submit_result.dart';
import '../entities/digital_card.dart';
import '../entities/redeem_result.dart';

abstract class BenefitsRepository {
  Future<List<Benefit>> listBenefits();
  Future<List<DigitalCard>> listMyDigitalCards();
  Future<RedeemBenefitOutcome> redeemBenefit(String benefitId);

  Future<List<Benefit>> adminListBenefits();
  Future<BenefitSubmitResult> createBenefit({
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
  });
  Future<BenefitSubmitResult> updateBenefit({
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
  });
  Future<BenefitSubmitResult> setBenefitActive(String id, bool active);

  /// Uploads a benefit image and returns its public URL.
  Future<String> uploadBenefitImage(File file);
}
