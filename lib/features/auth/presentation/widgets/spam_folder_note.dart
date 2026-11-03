import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// "If you can't find the email in your inbox, check your spam folder."
///
/// Shown directly under the confirmation that something was emailed — the
/// 6-digit code on `VerifyOtpScreen`, the reset link on
/// `ForgotPasswordScreen`. One widget rather than the same `Text` twice so
/// the two can't drift apart in wording, colour or spacing.
///
/// Deliberately in [AppColors.destructive] rather than the muted grey the
/// surrounding helper text uses: it is the line that rescues a user who would
/// otherwise sit on this screen believing no mail arrived, so it has to be
/// the thing their eye lands on, not more small print.
class SpamFolderNote extends StatelessWidget {
  const SpamFolderNote({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Text(
      l10n.authSpamFolderNote,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w600,
        color: AppColors.destructive,
      ),
    );
  }
}
