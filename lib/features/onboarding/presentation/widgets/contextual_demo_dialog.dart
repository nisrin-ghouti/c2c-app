import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_gradient_button.dart';

/// The app-styled dialog used by the (few) contextual demos that need a real
/// blocking modal rather than a spotlight — currently just Group Meetings,
/// whose explanation isn't tied to one specific on-screen element. Mirrors
/// the rounded-card look used across the app's other dialogs/sheets rather
/// than a bare `AlertDialog`.
Future<void> showContextualDemoDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline,
                color: AppColors.primaryStrong,
                size: 22,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 20),
            PrimaryGradientButton(
              label: l10n.actionGotIt,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}
