import 'dart:io';

import '../../domain/entities/benefit.dart';
import '../../domain/entities/benefit_submit_result.dart';
import '../../domain/entities/digital_card.dart';
import '../../domain/entities/redeem_result.dart';
import '../../domain/repositories/benefits_repository.dart';
import '../datasources/benefits_remote_data_source.dart';

class BenefitsRepositoryImpl implements BenefitsRepository {
  BenefitsRepositoryImpl(this._remote);

  final BenefitsRemoteDataSource _remote;

  @override
  Future<List<Benefit>> listBenefits() async {
    final rows = await _remote.listBenefits();
    return rows.map(_benefitFromRow).toList();
  }

  @override
  Future<List<DigitalCard>> listMyDigitalCards() async {
    final rows = await _remote.listMyDigitalCards();
    return rows.map(_cardFromRow).toList();
  }

  @override
  Future<RedeemBenefitOutcome> redeemBenefit(String benefitId) async {
    final result = await _remote.redeemBenefit(benefitId);
    final status = switch (result['status']) {
      'ok' => RedeemBenefitResult.ok,
      'already_active' => RedeemBenefitResult.alreadyActive,
      'insufficient_points' => RedeemBenefitResult.insufficientPoints,
      'inactive' => RedeemBenefitResult.inactive,
      'not_found' => RedeemBenefitResult.notFound,
      'not_a_student' => RedeemBenefitResult.notAStudent,
      _ => RedeemBenefitResult.unknown,
    };
    if (status != RedeemBenefitResult.ok) {
      return RedeemBenefitOutcome(result: status);
    }
    return RedeemBenefitOutcome(result: status, card: _cardFromRow(result));
  }

  @override
  Future<List<Benefit>> adminListBenefits() async {
    final rows = await _remote.adminListBenefits();
    return rows.map(_benefitFromRow).toList();
  }

  @override
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
  }) async {
    final result = await _remote.createBenefit(
      _benefitPayload(
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
      ),
    );
    return _submitResultFrom(result['status'] as String?);
  }

  @override
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
  }) async {
    final result = await _remote.updateBenefit(
      id,
      _benefitPayload(
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
      ),
    );
    return _submitResultFrom(result['status'] as String?);
  }

  /// The `jsonb` payload both `create_benefit` and `update_benefit` accept —
  /// kept in one place so the two stay in sync as fields are added.
  Map<String, dynamic> _benefitPayload({
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
  }) {
    return {
      'title': title,
      'description': description,
      'category': category,
      'point_cost': pointCost,
      'image_url': imageUrl,
      'partner_business_name': partnerBusinessName,
      'business_description': businessDescription,
      'how_to_redeem': howToRedeem,
      'external_link': externalLink,
      'location': location,
      'maps_link': mapsLink,
    };
  }

  @override
  Future<String> uploadBenefitImage(File file) =>
      _remote.uploadBenefitImage(file);

  @override
  Future<BenefitSubmitResult> setBenefitActive(String id, bool active) async {
    final result = await _remote.setBenefitActive(id, active);
    return _submitResultFrom(result['status'] as String?);
  }

  BenefitSubmitResult _submitResultFrom(String? status) => switch (status) {
    'ok' => BenefitSubmitResult.ok,
    'forbidden' => BenefitSubmitResult.forbidden,
    'not_found' => BenefitSubmitResult.notFound,
    _ => BenefitSubmitResult.unknown,
  };

  Benefit _benefitFromRow(Map<String, dynamic> row) {
    return Benefit(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String?,
      category: row['category'] as String?,
      pointCost: (row['point_cost'] as num).toInt(),
      imageUrl: row['image_url'] as String?,
      partnerBusinessName: row['partner_business_name'] as String?,
      businessDescription: row['business_description'] as String?,
      howToRedeem: row['how_to_redeem'] as String?,
      externalLink: row['external_link'] as String?,
      location: row['location'] as String?,
      mapsLink: row['maps_link'] as String?,
      active: row['active'] as bool? ?? true,
      titleEn: row['title_en'] as String?,
      titleAr: row['title_ar'] as String?,
      titleHe: row['title_he'] as String?,
      descriptionEn: row['description_en'] as String?,
      descriptionAr: row['description_ar'] as String?,
      descriptionHe: row['description_he'] as String?,
      locationEn: row['location_en'] as String?,
      locationAr: row['location_ar'] as String?,
      locationHe: row['location_he'] as String?,
      partnerBusinessNameEn: row['partner_business_name_en'] as String?,
      partnerBusinessNameAr: row['partner_business_name_ar'] as String?,
      partnerBusinessNameHe: row['partner_business_name_he'] as String?,
      businessDescriptionEn: row['business_description_en'] as String?,
      businessDescriptionAr: row['business_description_ar'] as String?,
      businessDescriptionHe: row['business_description_he'] as String?,
      howToRedeemEn: row['how_to_redeem_en'] as String?,
      howToRedeemAr: row['how_to_redeem_ar'] as String?,
      howToRedeemHe: row['how_to_redeem_he'] as String?,
    );
  }

  DigitalCard _cardFromRow(Map<String, dynamic> row) {
    return DigitalCard(
      id: row['id'] as String,
      benefitId: row['benefit_id'] as String,
      title: row['title'] as String,
      description: row['description'] as String?,
      category: row['category'] as String?,
      imageUrl: row['image_url'] as String?,
      partnerBusinessName: row['partner_business_name'] as String?,
      qrToken: row['qr_token'] as String,
      redemptionCode: row['redemption_code'] as String,
      isRedeemed: row['status'] == 'redeemed',
      pointsSpent: (row['points_spent'] as num).toInt(),
      redeemedAt: row['redeemed_at'] != null
          ? DateTime.parse(row['redeemed_at'] as String)
          : null,
      createdAt: DateTime.parse(row['created_at'] as String),
      titleEn: row['title_en'] as String?,
      titleAr: row['title_ar'] as String?,
      titleHe: row['title_he'] as String?,
      descriptionEn: row['description_en'] as String?,
      descriptionAr: row['description_ar'] as String?,
      descriptionHe: row['description_he'] as String?,
      partnerBusinessNameEn: row['partner_business_name_en'] as String?,
      partnerBusinessNameAr: row['partner_business_name_ar'] as String?,
      partnerBusinessNameHe: row['partner_business_name_he'] as String?,
    );
  }
}
