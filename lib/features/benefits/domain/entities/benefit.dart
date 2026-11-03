/// One catalog entry — a partner offer redeemable with points.
class Benefit {
  const Benefit({
    required this.id,
    required this.title,
    this.description,
    this.category,
    required this.pointCost,
    this.imageUrl,
    this.partnerBusinessName,
    this.businessDescription,
    this.howToRedeem,
    this.externalLink,
    this.location,
    this.mapsLink,
    this.active = true,
    this.titleEn,
    this.titleAr,
    this.titleHe,
    this.descriptionEn,
    this.descriptionAr,
    this.descriptionHe,
    this.locationEn,
    this.locationAr,
    this.locationHe,
    this.partnerBusinessNameEn,
    this.partnerBusinessNameAr,
    this.partnerBusinessNameHe,
    this.businessDescriptionEn,
    this.businessDescriptionAr,
    this.businessDescriptionHe,
    this.howToRedeemEn,
    this.howToRedeemAr,
    this.howToRedeemHe,
  });

  final String id;
  final String title;

  /// What the benefit itself is.
  final String? description;
  final String? category;
  final int pointCost;
  final String? imageUrl;
  final String? partnerBusinessName;

  /// About the partner business (distinct from the benefit description).
  final String? businessDescription;

  /// Redemption instructions shown on the benefit profile.
  final String? howToRedeem;

  /// Instagram / website / Facebook / etc.
  final String? externalLink;

  final String? location;

  /// Optional Google Maps URL for [location].
  final String? mapsLink;

  /// Only populated (and only ever `false`) for the admin editor — the
  /// student-facing catalog already filters to active benefits server-side.
  final bool active;

  /// Per-locale translations — same pattern as `CampusEvent.titleAr`/etc.
  /// `title`/`description`/etc. (undecorated) hold whatever was originally
  /// typed, in whatever language that happened to be — the `_en` slot is
  /// NOT assumed to equal the canonical field.
  final String? titleEn;
  final String? titleAr;
  final String? titleHe;
  final String? descriptionEn;
  final String? descriptionAr;
  final String? descriptionHe;
  final String? locationEn;
  final String? locationAr;
  final String? locationHe;
  final String? partnerBusinessNameEn;
  final String? partnerBusinessNameAr;
  final String? partnerBusinessNameHe;
  final String? businessDescriptionEn;
  final String? businessDescriptionAr;
  final String? businessDescriptionHe;
  final String? howToRedeemEn;
  final String? howToRedeemAr;
  final String? howToRedeemHe;

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

  /// The description to show for [languageCode] — same fallback rule as
  /// [localizedTitle].
  String? localizedDescription(String languageCode) => _localize(
    languageCode,
    description,
    descriptionEn,
    descriptionAr,
    descriptionHe,
  );

  /// Same fallback rule as [localizedTitle], for the venue/address text.
  String? localizedLocation(String languageCode) =>
      _localize(languageCode, location, locationEn, locationAr, locationHe);

  /// Same fallback rule as [localizedTitle], for the partner business's name.
  String? localizedPartnerBusinessName(String languageCode) => _localize(
    languageCode,
    partnerBusinessName,
    partnerBusinessNameEn,
    partnerBusinessNameAr,
    partnerBusinessNameHe,
  );

  /// Same fallback rule as [localizedTitle], for the "About the business" text.
  String? localizedBusinessDescription(String languageCode) => _localize(
    languageCode,
    businessDescription,
    businessDescriptionEn,
    businessDescriptionAr,
    businessDescriptionHe,
  );

  /// Same fallback rule as [localizedTitle], for the redemption instructions.
  String? localizedHowToRedeem(String languageCode) => _localize(
    languageCode,
    howToRedeem,
    howToRedeemEn,
    howToRedeemAr,
    howToRedeemHe,
  );
}
