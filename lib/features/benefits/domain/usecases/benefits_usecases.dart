import 'dart:io';

import '../entities/benefit.dart';
import '../entities/benefit_submit_result.dart';
import '../entities/digital_card.dart';
import '../entities/redeem_result.dart';
import '../repositories/benefits_repository.dart';

class ListBenefits {
  const ListBenefits(this._repository);
  final BenefitsRepository _repository;

  Future<List<Benefit>> call() => _repository.listBenefits();
}

class ListMyDigitalCards {
  const ListMyDigitalCards(this._repository);
  final BenefitsRepository _repository;

  Future<List<DigitalCard>> call() => _repository.listMyDigitalCards();
}

class RedeemBenefit {
  const RedeemBenefit(this._repository);
  final BenefitsRepository _repository;

  Future<RedeemBenefitOutcome> call(String benefitId) =>
      _repository.redeemBenefit(benefitId);
}

class AdminListBenefits {
  const AdminListBenefits(this._repository);
  final BenefitsRepository _repository;

  Future<List<Benefit>> call() => _repository.adminListBenefits();
}

class CreateBenefit {
  const CreateBenefit(this._repository);
  final BenefitsRepository _repository;

  Future<BenefitSubmitResult> call({
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
  }) => _repository.createBenefit(
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
}

class UpdateBenefit {
  const UpdateBenefit(this._repository);
  final BenefitsRepository _repository;

  Future<BenefitSubmitResult> call({
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
  }) => _repository.updateBenefit(
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
}

class SetBenefitActive {
  const SetBenefitActive(this._repository);
  final BenefitsRepository _repository;

  Future<BenefitSubmitResult> call(String id, bool active) =>
      _repository.setBenefitActive(id, active);
}

class UploadBenefitImage {
  const UploadBenefitImage(this._repository);
  final BenefitsRepository _repository;

  Future<String> call(File file) => _repository.uploadBenefitImage(file);
}
