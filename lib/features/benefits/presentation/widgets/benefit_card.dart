import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../admin/domain/entities/option_list_type.dart';
import '../../../admin/presentation/providers/option_label_providers.dart';
import '../../domain/entities/benefit.dart';

/// Catalog entry card — mirrors `CampusEventCard`'s visual shape (thumbnail
/// + category pill + title + meta row), swapping the meta row for a point
/// cost and a redeem button.
class BenefitCard extends StatelessWidget {
  const BenefitCard({
    super.key,
    required this.benefit,
    required this.canAfford,
    required this.hasActiveCard,
    required this.redeeming,
    required this.onRedeem,
    this.onTap,
  });

  final Benefit benefit;
  final bool canAfford;

  /// Whether the student already holds an unredeemed digital card for this
  /// benefit — while true, redemption stays disabled regardless of points.
  final bool hasActiveCard;
  final bool redeeming;
  final VoidCallback onRedeem;

  /// Opens the benefit's full profile. Available regardless of whether the
  /// student can afford it — insufficient points only disables Redeem.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final title = benefit.localizedTitle(languageCode);
    final description = benefit.localizedDescription(languageCode);
    final partnerBusinessName = benefit.localizedPartnerBusinessName(
      languageCode,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: benefit.imageUrl != null && benefit.imageUrl!.isNotEmpty
                  ? Image.network(
                      benefit.imageUrl!,
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 84,
                      height: 84,
                      color: AppColors.surfaceMuted,
                      alignment: Alignment.center,
                      child: const Text('🎁', style: TextStyle(fontSize: 28)),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          l10n.benefitPointCost(benefit.pointCost),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryForeground,
                          ),
                        ),
                      ),
                      if (benefit.category != null &&
                          benefit.category!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.sky.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: OptionLabelText(
                              type: OptionListType.benefitCategory,
                              value: benefit.category,
                              style: const TextStyle(fontSize: 10),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  if (partnerBusinessName != null &&
                      partnerBusinessName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      partnerBusinessName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Material(
                      color: hasActiveCard
                          ? AppColors.success.withValues(alpha: 0.18)
                          : canAfford
                          ? AppColors.primaryStrong
                          : AppColors.mutedForeground.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: canAfford && !redeeming && !hasActiveCard
                            ? onRedeem
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: redeeming
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      hasActiveCard
                                          ? Icons.check_circle_outline
                                          : canAfford
                                          ? Icons.redeem
                                          : Icons.lock_outline,
                                      size: 14,
                                      color: hasActiveCard
                                          ? AppColors.success
                                          : canAfford
                                          ? Colors.white
                                          : AppColors.mutedForeground,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      hasActiveCard
                                          ? l10n.benefitAlreadyActiveLabel
                                          : canAfford
                                          ? l10n.benefitRedeemAction
                                          : l10n.benefitNotEnoughPoints,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: hasActiveCard
                                            ? AppColors.success
                                            : canAfford
                                            ? Colors.white
                                            : AppColors.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
