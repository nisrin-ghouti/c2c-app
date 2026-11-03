import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../domain/entities/benefit.dart';
import '../../domain/entities/redeem_result.dart';
import '../controllers/redeem_benefit_controller.dart';
import '../providers/benefits_providers.dart';
import 'benefit_profile_screen.dart';
import 'card_detail_screen.dart';

/// Resolves a bare benefit id (e.g. from a notification's `data` payload)
/// into the full [Benefit] the real profile screen needs, then hands off to
/// it, wired up with the same redeem flow `BenefitsScreen` uses — so tapping
/// a benefit notification lands on that specific benefit instead of the
/// generic catalog.
class BenefitNotificationOpener extends ConsumerStatefulWidget {
  const BenefitNotificationOpener({super.key, required this.benefitId});

  final String benefitId;

  @override
  ConsumerState<BenefitNotificationOpener> createState() =>
      _BenefitNotificationOpenerState();
}

class _BenefitNotificationOpenerState
    extends ConsumerState<BenefitNotificationOpener> {
  bool _redeeming = false;

  Future<void> _redeem(Benefit benefit, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.benefitRedeemConfirmTitle),
        content: Text(
          l10n.benefitRedeemConfirmMessage(benefit.title, benefit.pointCost),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.benefitRedeemAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _redeeming = true);
    final outcome = await ref
        .read(redeemBenefitControllerProvider.notifier)
        .redeem(benefit.id);
    if (!mounted) return;
    setState(() => _redeeming = false);

    if (outcome.result == RedeemBenefitResult.ok && outcome.card != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CardDetailScreen(card: outcome.card!),
        ),
      );
      return;
    }

    final message = switch (outcome.result) {
      RedeemBenefitResult.alreadyActive => l10n.benefitRedeemErrorAlreadyActive,
      RedeemBenefitResult.insufficientPoints =>
        l10n.benefitRedeemErrorInsufficientPoints,
      RedeemBenefitResult.inactive ||
      RedeemBenefitResult.notFound => l10n.benefitRedeemErrorUnavailable,
      RedeemBenefitResult.notAStudent => l10n.benefitRedeemErrorNotAStudent,
      _ => l10n.benefitRedeemErrorGeneric,
    };
    if (outcome.result == RedeemBenefitResult.alreadyActive) {
      ref.invalidate(myDigitalCardsProvider);
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final benefitAsync = ref.watch(benefitByIdProvider(widget.benefitId));
    final points =
        ref.watch(homeDashboardProvider).valueOrNull?.summary.points ?? 0;
    final activeCardBenefitIds =
        (ref.watch(myDigitalCardsProvider).valueOrNull ?? const [])
            .where((c) => !c.isRedeemed)
            .map((c) => c.benefitId)
            .toSet();
    // Keeps the autoDispose redeem controller alive across the redeem() await.
    ref.watch(redeemBenefitControllerProvider);

    return benefitAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.notificationTargetLoadError)),
      ),
      data: (benefit) {
        if (benefit == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.notificationTargetLoadError)),
          );
        }
        return BenefitProfileScreen(
          benefit: benefit,
          canAfford: points >= benefit.pointCost,
          hasActiveCard: activeCardBenefitIds.contains(benefit.id),
          redeeming: _redeeming,
          onRedeem: () => _redeem(benefit, l10n),
        );
      },
    );
  }
}
