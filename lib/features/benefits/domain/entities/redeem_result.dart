import 'digital_card.dart';

enum RedeemBenefitResult {
  ok,
  alreadyActive,
  insufficientPoints,
  inactive,
  notFound,
  notAStudent,
  unknown,
}

/// Pairs the outcome with the freshly-created card, so the UI can jump
/// straight to its detail screen (with QR) on success.
class RedeemBenefitOutcome {
  const RedeemBenefitOutcome({required this.result, this.card});

  final RedeemBenefitResult result;
  final DigitalCard? card;
}
