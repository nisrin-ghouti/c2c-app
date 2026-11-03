import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../onboarding/domain/entities/demo_key.dart';
import '../../../onboarding/presentation/controllers/demo_flags_controller.dart';
import '../../../onboarding/presentation/widgets/contextual_showcase.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/digital_card.dart';
import '../providers/benefits_providers.dart';
import '../widgets/digital_card_view.dart';

/// Full-screen wallet card — shown to partner staff to redeem. A redeemed card
/// still opens here (read-only, no QR) so history stays browsable.
///
/// The card body itself lives in [DigitalCardView], shared with the admin
/// preview so both always render identically.
///
/// [card] is the snapshot whoever pushed this route was holding. It is the
/// starting value only: the screen then follows the live row, so the partner
/// scanning the QR flips the status and removes the barcode under the
/// student's hand instead of waiting for them to back out and return.
class CardDetailScreen extends ConsumerWidget {
  CardDetailScreen({super.key, required this.card});

  final DigitalCard card;

  /// Stable for the lifetime of this pushed route (the widget instance
  /// itself isn't recreated by unrelated rebuilds), so this is safe to
  /// declare here rather than needing a `ConsumerStatefulWidget`.
  final _qrShowcaseKey = GlobalKey();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Subscribe for as long as this card is on screen; torn down on pop.
    ref.watch(digitalCardsLiveRefreshProvider);
    // Follow the live row, but never blank out the card the student is holding
    // up: while the refetch is in flight, or if it fails, the snapshot this
    // route was pushed with still renders.
    final card =
        ref.watch(digitalCardByIdProvider(this.card.id)).valueOrNull ??
        this.card;

    // The cardholder name lives on the profile, not the card row. Falling back
    // to an empty string rather than blocking on the profile load keeps the QR
    // reachable even if that request is slow or fails.
    final studentName =
        ref.watch(myProfileProvider).valueOrNull?.fullName ?? '';
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final title = card.localizedTitle(languageCode);
    final description = card.localizedDescription(languageCode);
    final businessName = card.localizedPartnerBusinessName(languageCode);

    // Nothing to redeem/spotlight on an already-used card.
    //
    // `canDemo` deliberately does NOT include the "seen" flag: it decides
    // whether the QR is WRAPPED, and `startContextualDemoOnce` marks the demo
    // seen immediately after starting it. Folding the flag in here meant that
    // markSeen rebuilt the screen, dropped the wrapper, and unmounted the very
    // target the running showcase pointed at — so the spotlight never
    // appeared. Only the decision to START the demo consults the flag.
    final canDemo = !card.isRedeemed;
    final showDemo =
        canDemo && !ref.watch(hasSeenDemoProvider(DemoKey.digitalCard));
    if (showDemo) {
      startContextualDemoOnce(
        context: context,
        ref: ref,
        key: DemoKey.digitalCard,
        showcaseKeys: [_qrShowcaseKey],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: DigitalCardView(
              benefitTitle: title,
              studentName: studentName,
              businessName: businessName,
              description: description,
              createdAt: card.createdAt,
              qrValue: card.qrValue,
              redemptionCode: card.redemptionCode,
              isRedeemed: card.isRedeemed,
              redeemedAt: card.redeemedAt,
              qrAreaWrapper: canDemo
                  ? (child) => ContextualShowcase(
                      showcaseKey: _qrShowcaseKey,
                      title: l10n.demoDigitalCardTitle,
                      description: l10n.demoDigitalCardMessage,
                      child: child,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
