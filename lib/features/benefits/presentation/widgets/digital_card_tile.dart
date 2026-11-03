import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/digital_card.dart';

class DigitalCardTile extends StatelessWidget {
  const DigitalCardTile({
    super.key,
    required this.card,
    required this.studentName,
    required this.onTap,
  });

  final DigitalCard card;
  final String studentName;
  final VoidCallback onTap;

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  static String _time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final title = card.localizedTitle(languageCode);
    final partnerBusinessName = card.localizedPartnerBusinessName(languageCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: card.isRedeemed
            ? AppColors.mutedForeground.withValues(alpha: 0.1)
            : AppColors.success.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: card.isRedeemed
              ? AppColors.mutedForeground.withValues(alpha: 0.25)
              : AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: card.imageUrl != null && card.imageUrl!.isNotEmpty
                      ? Image.network(
                          card.imageUrl!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 64,
                          height: 64,
                          color: AppColors.surfaceMuted,
                          alignment: Alignment.center,
                          child: const Text(
                            '🎁',
                            style: TextStyle(fontSize: 24),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _StatusPill(isRedeemed: card.isRedeemed, l10n: l10n),
                        ],
                      ),
                      if (partnerBusinessName != null &&
                          partnerBusinessName.isNotEmpty)
                        Text(
                          partnerBusinessName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      const SizedBox(height: 6),
                      _MetaRow(
                        icon: Icons.calendar_today_outlined,
                        text: _date(card.createdAt),
                      ),
                      const SizedBox(height: 2),
                      _MetaRow(icon: Icons.person_outline, text: studentName),
                      if (card.isRedeemed && card.redeemedAt != null) ...[
                        const SizedBox(height: 2),
                        _MetaRow(
                          icon: Icons.check_circle_outline,
                          text:
                              '${_time(card.redeemedAt!)} · ${_date(card.redeemedAt!)}',
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: card.isRedeemed
                        ? AppColors.mutedForeground
                        : AppColors.success,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.qr_code_2,
                        size: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.benefitCardOpenAction,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isRedeemed, required this.l10n});

  final bool isRedeemed;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (!isRedeemed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          l10n.benefitCardAvailableTag,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.mutedForeground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 10, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            l10n.benefitCardRedeemedTag,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.mutedForeground),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }
}
