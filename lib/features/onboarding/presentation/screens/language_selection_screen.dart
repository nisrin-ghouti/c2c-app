import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/localization/supported_locales.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/primary_gradient_button.dart';
import '../widgets/language_option_tile.dart';

/// Shown exactly once, on first launch, before any other route — the user
/// must pick a language before the auth flow (or anything else) becomes
/// reachable. See [hasChosenLanguageProvider] / app_router.dart for the gate.
class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  AppLocale _selected = SupportedLocales.english;

  Future<void> _continue() async {
    await ref
        .read(localeControllerProvider.notifier)
        .setLocale(_selected.locale);
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.hero),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AppLogo(height: 96)),
                    const SizedBox(height: 20),
                    Text(
                      l10n.languageSelectionTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.foreground,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.languageSelectionSubtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.foreground.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.foreground.withValues(alpha: 0.14),
                            blurRadius: 40,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final option in SupportedLocales.all) ...[
                            LanguageOptionTile(
                              option: option,
                              selected: option == _selected,
                              onTap: () => setState(() => _selected = option),
                            ),
                            if (option != SupportedLocales.all.last)
                              const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 20),
                          PrimaryGradientButton(
                            label: l10n.languageContinue,
                            onPressed: _continue,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
