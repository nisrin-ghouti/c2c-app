import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/auth_scaffold.dart';
import '../../../../core/widgets/auth_text_field.dart';
import '../../../../core/widgets/inline_banner.dart';
import '../../../../core/widgets/primary_gradient_button.dart';
import '../controllers/auth_message_kind.dart';
import '../controllers/reset_password_controller.dart';
import '../providers/auth_providers.dart';

/// Reached via the password-reset email link, which signs the user into a
/// short-lived recovery session — `currentAuthSessionProvider` becomes
/// authenticated once Supabase has exchanged that link for a session.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(resetPasswordControllerProvider.notifier)
        .submit(_passwordController.text);
    if (!mounted || !ok) return;
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(resetPasswordControllerProvider);
    final ready = ref.watch(currentAuthSessionProvider).isAuthenticated;

    return AuthScaffold(
      title: l10n.resetTitle,
      child: !ready
          ? Text(
              l10n.resetLinkInactive,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedForeground),
            )
          : Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTextField(
                    controller: _passwordController,
                    label: l10n.fieldPassword,
                    hint: l10n.fieldNewPasswordHint,
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: (v) => Validators.password(l10n, v),
                  ),
                  const SizedBox(height: 12),
                  AuthTextField(
                    controller: _confirmController,
                    label: l10n.fieldConfirmPassword,
                    icon: Icons.lock_outline,
                    obscureText: true,
                    validator: (v) => Validators.confirmPassword(
                      l10n,
                      v,
                      _passwordController.text,
                    ),
                  ),
                  if (state.errorKind != null) ...[
                    const SizedBox(height: 12),
                    InlineBanner(
                      message: state.errorKind!.message(l10n),
                      tone: BannerTone.error,
                    ),
                  ],
                  if (state.infoKind != null) ...[
                    const SizedBox(height: 12),
                    InlineBanner(
                      message: state.infoKind!.message(l10n),
                      tone: BannerTone.success,
                    ),
                  ],
                  const SizedBox(height: 20),
                  PrimaryGradientButton(
                    label: l10n.buttonUpdatePassword,
                    loading: state.loading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
    );
  }
}
