import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum BannerTone { error, success, neutral }

/// The small rounded status strips (`bg-destructive/15`, `bg-success/15`
/// in the reference app) used to surface form errors and confirmations.
/// `neutral` (muted, no strong color) is used for "this hasn't happened
/// yet" states — e.g. an upcoming (not yet attended/missed) My Events card.
class InlineBanner extends StatelessWidget {
  const InlineBanner({super.key, required this.message, required this.tone});

  final String message;
  final BannerTone tone;

  Color get _color => switch (tone) {
    BannerTone.error => AppColors.destructive,
    BannerTone.success => AppColors.success,
    BannerTone.neutral => AppColors.mutedForeground,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: tone == BannerTone.neutral ? 0.08 : 0.15,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: tone == BannerTone.success ? AppColors.foreground : color,
        ),
      ),
    );
  }
}
