/// A redeemed-or-redeemable card in the student's wallet — denormalized
/// with its benefit's display fields so the wallet list and card-detail
/// screen don't need a second lookup.
class DigitalCard {
  const DigitalCard({
    required this.id,
    required this.benefitId,
    required this.title,
    this.description,
    this.category,
    this.imageUrl,
    this.partnerBusinessName,
    required this.qrToken,
    required this.redemptionCode,
    required this.isRedeemed,
    required this.pointsSpent,
    this.redeemedAt,
    required this.createdAt,
    this.titleEn,
    this.titleAr,
    this.titleHe,
    this.descriptionEn,
    this.descriptionAr,
    this.descriptionHe,
    this.partnerBusinessNameEn,
    this.partnerBusinessNameAr,
    this.partnerBusinessNameHe,
  });

  final String id;
  final String benefitId;
  final String title;
  final String? description;
  final String? category;
  final String? imageUrl;
  final String? partnerBusinessName;
  final String qrToken;

  /// Per-locale translations, carried over from the underlying `benefits`
  /// row — same pattern as `Benefit.titleAr`/etc.
  final String? titleEn;
  final String? titleAr;
  final String? titleHe;
  final String? descriptionEn;
  final String? descriptionAr;
  final String? descriptionHe;
  final String? partnerBusinessNameEn;
  final String? partnerBusinessNameAr;
  final String? partnerBusinessNameHe;

  static String? _localize(
    String languageCode,
    String? canonical,
    String? en,
    String? ar,
    String? he,
  ) {
    final translated = switch (languageCode) {
      'en' => en,
      'ar' => ar,
      'he' => he,
      _ => null,
    };
    if (translated != null && translated.trim().isNotEmpty) return translated;
    return canonical;
  }

  /// The title to show for [languageCode] — falls back to the canonical
  /// [title] whenever no translation was entered for that locale.
  String localizedTitle(String languageCode) =>
      _localize(languageCode, title, titleEn, titleAr, titleHe)!;

  /// Same fallback rule as [localizedTitle].
  String? localizedDescription(String languageCode) => _localize(
    languageCode,
    description,
    descriptionEn,
    descriptionAr,
    descriptionHe,
  );

  /// Same fallback rule as [localizedTitle], for the partner business's name.
  String? localizedPartnerBusinessName(String languageCode) => _localize(
    languageCode,
    partnerBusinessName,
    partnerBusinessNameEn,
    partnerBusinessNameAr,
    partnerBusinessNameHe,
  );

  /// Short human-readable fallback for when the QR can't be scanned — the
  /// student reads this out, the business partner types it into "Enter
  /// code manually" instead of scanning.
  final String redemptionCode;
  final bool isRedeemed;
  final int pointsSpent;
  final DateTime? redeemedAt;
  final DateTime createdAt;

  /// Opens directly in any phone's stock camera app — no login and no
  /// C2C app required. Points at the Firebase-hosted confirmation page,
  /// which calls the public `redeem-benefit` Edge Function (JSON API) to
  /// show the benefit and confirm the redemption. (Supabase's edge gateway
  /// won't serve real HTML from a *.supabase.co URL, so the page itself
  /// has to be hosted elsewhere.)
  String get qrValue => 'https://connecttocollect-858b6.web.app/r/$qrToken';
}
