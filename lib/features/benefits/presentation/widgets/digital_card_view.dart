import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// The digital benefit card a student presents to the business owner.
///
/// Deliberately a *dumb* widget taking primitives rather than a [DigitalCard]:
/// the admin "preview" needs to render this exact layout from unsaved form
/// values, before any card row exists. Sharing one widget between the real
/// wallet card and the preview is the whole point — a preview built from a
/// separate layout would silently drift from what students actually see.
///
/// Per spec, every card carries: benefit name, student name, business name,
/// creation date, a unique QR code, and the card status. A redeemed card is
/// rendered in muted greys with the QR replaced by a "used" stamp, so partner
/// staff can tell at a glance that it can't be redeemed twice.
class DigitalCardView extends StatelessWidget {
  const DigitalCardView({
    super.key,
    required this.benefitTitle,
    required this.studentName,
    this.businessName,
    this.description,
    required this.createdAt,
    required this.qrValue,
    required this.redemptionCode,
    required this.isRedeemed,
    this.redeemedAt,
    this.qrAreaWrapper,
  });

  final String benefitTitle;
  final String studentName;
  final String? businessName;
  final String? description;
  final DateTime createdAt;
  final String qrValue;

  /// Short numeric fallback shown as legible text — the QR alone gives the
  /// student nothing they can read out when "Enter code manually" is the
  /// only option (camera broken, bad lighting, no app on the partner side).
  final String redemptionCode;
  final bool isRedeemed;
  final DateTime? redeemedAt;

  /// Optionally wraps the QR block — lets the real wallet screen spotlight
  /// it for the first-time "how to redeem" demo without this otherwise-dumb,
  /// admin-preview-shared widget needing to know anything about showcaseview.
  final Widget Function(Widget child)? qrAreaWrapper;

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Status colours carry the whole card: a soft green wash while the card
    // can still be redeemed, a soft red wash once it's used up — matching how
    // partner staff scan for "is this card good" at a glance.
    final statusColor = isRedeemed ? AppColors.destructive : AppColors.success;
    final surface = statusColor.withValues(alpha: 0.22);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (businessName != null && businessName!.isNotEmpty)
            Text(
              businessName!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.mutedForeground,
              ),
            ),
          const SizedBox(height: 2),
          Text(
            benefitTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          if (description != null && description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(description!, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 16),

          // Cardholder — required by spec so staff can check the card against
          // the person standing in front of them.
          Text(
            l10n.benefitCardStudentLabel,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.mutedForeground,
            ),
          ),
          Text(
            studentName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),

          if (!isRedeemed) ...[
            // White QR background regardless of theme — scanners need the
            // light/dark contrast, and the status tint is not guaranteed white.
            (qrAreaWrapper ?? (child) => child)(
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: QrImageView(
                  data: qrValue,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.benefitCardShowHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.benefitCardCodeLabel,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.mutedForeground,
              ),
            ),
            Text(
              redemptionCode,
              // Always LTR, same reasoning as the Student ID display: the
              // business partner reads digits off the screen exactly as
              // shown, regardless of the app's RTL/LTR language.
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 16),
          ],

          Text(
            l10n.benefitCardStatusLabel,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isRedeemed
                  ? l10n.benefitCardRedeemedTag
                  : l10n.benefitCardAvailableTag,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 14),
          Text(
            l10n.benefitCardAcquiredOn(_date(createdAt)),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedForeground,
            ),
          ),
          if (isRedeemed && redeemedAt != null)
            Text(
              l10n.benefitCardRedeemedOn(_date(redeemedAt!)),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.mutedForeground,
              ),
            ),
        ],
      ),
    );
  }
}
