import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// Red note under the First/Last name fields explaining that the name entered
/// is the one event organizers will see, so it must be a real full name and
/// not a nickname.
///
/// Advisory only — it never blocks submission on its own. The fields keep
/// their existing "required" validators, which are what actually gate the
/// form; this explains *why* the value matters, which a validator message
/// fired after the fact cannot.
///
/// One widget shared by onboarding and profile editing so the wording and
/// colour stay identical in both.
class FullNameWarning extends StatelessWidget {
  const FullNameWarning({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        l10n.profileFullNameWarning,
        style: const TextStyle(
          fontSize: 12,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: AppColors.destructive,
        ),
      ),
    );
  }
}
