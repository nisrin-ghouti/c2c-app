import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/external_link_value.dart';
import '../../../admin/domain/entities/option_list_type.dart';
import '../../../admin/presentation/providers/option_label_providers.dart';
import '../../domain/entities/benefit.dart';

/// A benefit's full profile.
///
/// Openable for **any** published benefit — a student who can't afford it can
/// still read everything; only the Redeem button is disabled. Field order
/// follows the spec: title, image, business name, benefit description,
/// business description, points cost, how to redeem, external link, location,
/// category.
class BenefitProfileScreen extends StatelessWidget {
  const BenefitProfileScreen({
    super.key,
    required this.benefit,
    this.canAfford = false,
    this.hasActiveCard = false,
    this.redeeming = false,
    this.onRedeem,
  });

  final Benefit benefit;
  final bool canAfford;

  /// Whether the student already holds an unredeemed digital card for this
  /// benefit — while true, redemption stays disabled regardless of points.
  final bool hasActiveCard;
  final bool redeeming;

  /// Null hides the redeem action entirely (e.g. an admin previewing).
  final VoidCallback? onRedeem;

  bool _has(String? value) => value != null && value.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final title = benefit.localizedTitle(languageCode);
    final description = benefit.localizedDescription(languageCode);
    final partnerBusinessName = benefit.localizedPartnerBusinessName(
      languageCode,
    );
    final businessDescription = benefit.localizedBusinessDescription(
      languageCode,
    );
    final howToRedeem = benefit.localizedHowToRedeem(languageCode);
    final location = benefit.localizedLocation(languageCode);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            // 1. Title
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),

            // 2. Image
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _has(benefit.imageUrl)
                  ? Image.network(
                      benefit.imageUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _ImageFallback(),
                    )
                  : const _ImageFallback(),
            ),

            // 3. Business name
            if (_has(partnerBusinessName)) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.storefront_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      partnerBusinessName!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // 4. Benefit description
            if (description != null && description.trim().isNotEmpty)
              _Section(
                title: l10n.benefitProfileAboutBenefit,
                icon: Icons.card_giftcard_outlined,
                child: Text(description),
              ),

            // 5. Business description
            if (_has(businessDescription))
              _Section(
                title: l10n.benefitProfileAboutBusiness,
                icon: Icons.info_outline,
                child: Text(businessDescription!),
              ),

            // 6. Points cost
            _Section(
              title: l10n.benefitProfileCostLabel,
              icon: Icons.stars_outlined,
              child: Text(
                l10n.benefitPointCost(benefit.pointCost),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),

            // 7. How to redeem
            if (_has(howToRedeem))
              _Section(
                title: l10n.benefitProfileHowToRedeem,
                icon: Icons.qr_code_2_outlined,
                child: Text(howToRedeem!),
              ),

            // 8. External link
            if (_has(benefit.externalLink))
              _Section(
                title: l10n.benefitProfileLinkLabel,
                icon: Icons.link,
                child: ExternalLinkValue(value: benefit.externalLink!),
              ),

            // 9. Location (+ optional maps link)
            if (_has(location) || _has(benefit.mapsLink))
              _Section(
                title: l10n.benefitProfileLocationLabel,
                icon: Icons.location_on_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_has(location)) Text(location!),
                    if (_has(benefit.mapsLink)) ...[
                      const SizedBox(height: 6),
                      ExternalLinkValue(value: benefit.mapsLink!),
                    ],
                  ],
                ),
              ),

            // 10. Category
            if (_has(benefit.category))
              _Section(
                title: l10n.benefitProfileCategoryLabel,
                icon: Icons.sell_outlined,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.sky.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: OptionLabelText(
                      type: OptionListType.benefitCategory,
                      value: benefit.category,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),

            if (onRedeem != null) ...[
              const SizedBox(height: 24),
              if (hasActiveCard)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.benefitAlreadyActiveMessage,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: (canAfford && !redeeming) ? onRedeem : null,
                    child: redeeming
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            canAfford
                                ? l10n.benefitRedeemAction
                                : l10n.benefitNotEnoughPoints,
                          ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      color: AppColors.surfaceMuted,
      alignment: Alignment.center,
      child: const Text('🎁', style: TextStyle(fontSize: 44)),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DefaultTextStyle(
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.foreground,
                height: 1.4,
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
