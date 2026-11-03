import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/auth_scaffold.dart';
import '../../../../core/widgets/primary_gradient_button.dart';
import '../providers/auth_providers.dart';

/// Dead-end screen the router sends Admin/Host-only accounts to — see
/// `isStudentEligibleProvider` and the `appRouterProvider` redirect. This
/// app is student-facing only, so those accounts have nothing to do here
/// beyond signing out.
class StudentAppRestrictedScreen extends ConsumerWidget {
  const StudentAppRestrictedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AuthScaffold(
      title: l10n.restrictedAccessTitle,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.restrictedAccessMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 24),
          PrimaryGradientButton(
            label: l10n.actionSignOut,
            onPressed: () => ref.read(signOutProvider)(),
          ),
        ],
      ),
    );
  }
}
