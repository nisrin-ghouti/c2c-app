import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_config.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/auth_scaffold.dart';
import '../../../../core/widgets/auth_text_field.dart';
import '../../../../core/widgets/inline_banner.dart';
import '../../../../core/widgets/primary_gradient_button.dart';
import '../../../../core/widgets/segmented_toggle.dart';
import '../controllers/auth_form_controller.dart';
import '../controllers/auth_message_kind.dart';
import '../navigation/post_auth_navigation.dart';

/// Combined login/signup screen — mirrors the reference web app's
/// single `/auth` route, which switches its form between four states
/// (login+password, login+otp, signup) rather than being four screens.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _blockedDialogShown = false;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  AuthMode _mode = AuthMode.login;
  LoginMethod _method = LoginMethod.password;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _showPasswordField =>
      _mode == AuthMode.signup ||
      (_mode == AuthMode.login && _method == LoginMethod.password);

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim().toLowerCase();
    final controller = ref.read(authFormControllerProvider.notifier);

    final outcome = _mode == AuthMode.signup
        ? await controller.submitSignup(
            email: email,
            password: _passwordController.text,
            fullName:
                '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
          )
        : await controller.submitLogin(
            email: email,
            password: _passwordController.text,
            method: _method,
          );

    if (!mounted || outcome == null) return;

    switch (outcome) {
      case NavigateToVerify(:final email):
        context.push(AppRoutes.verifyOtp, extra: email);
      case NavigateToDestination(:final destination):
        // Commits the field values to the platform's password manager (Google
        // Password Manager / iOS Keychain) so it offers to save them, and on a
        // future login offers to autofill — the standard, OS-secured way apps
        // "remember" credentials rather than the app storing them itself.
        TextInput.finishAutofillContext();
        context.goToPostAuthDestination(destination);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(authFormControllerProvider);
    if (state.errorKind == AuthErrorKind.blockedUser && !_blockedDialogShown) {
      _blockedDialogShown = true;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            content: Text(l10n.errorBlockedUser),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.actionClose),
              ),
            ],
          ),
        );

        if (mounted) {
          _blockedDialogShown = false;
        }
      });
    }
    final buttonLabel = switch ((_mode, _method)) {
      (AuthMode.signup, _) => l10n.buttonCreateAccount,
      (AuthMode.login, LoginMethod.password) => l10n.buttonLogin,
      (AuthMode.login, LoginMethod.otp) => l10n.buttonSendCode,
    };

    return AuthScaffold(
      title: l10n.welcomeTitle,
      subtitle: l10n.welcomeSubtitle,
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logical order [login, signup] mirrors the reference app's DOM
              // order so RTL/LTR both render the tabs in the right spot.
              SegmentedToggle<AuthMode>(
                value: _mode,
                options: [
                  SegmentOption(value: AuthMode.login, label: l10n.tabLogin),
                  SegmentOption(value: AuthMode.signup, label: l10n.tabSignup),
                ],
                onChanged: (mode) => setState(() => _mode = mode),
              ),
              if (_mode == AuthMode.login) ...[
                const SizedBox(height: 12),
                SegmentedToggle<LoginMethod>(
                  compact: true,
                  value: _method,
                  options: [
                    SegmentOption(
                      value: LoginMethod.password,
                      label: l10n.methodPassword,
                    ),
                    SegmentOption(
                      value: LoginMethod.otp,
                      label: l10n.methodOtp,
                    ),
                  ],
                  onChanged: (method) => setState(() => _method = method),
                ),
              ],
              const SizedBox(height: 16),
              if (_mode == AuthMode.signup) ...[
                AuthTextField(
                  controller: _firstNameController,
                  label: l10n.fieldFirstName,
                  icon: Icons.person_outline,
                  validator: (v) =>
                      Validators.requiredField(v, l10n.errorEnterFirstName),
                ),
                const SizedBox(height: 12),
                AuthTextField(
                  controller: _lastNameController,
                  label: l10n.fieldLastName,
                  icon: Icons.person_outline,
                  validator: (v) =>
                      Validators.requiredField(v, l10n.errorEnterLastName),
                ),
                const SizedBox(height: 12),
              ],
              AuthTextField(
                controller: _emailController,
                label: l10n.fieldEmail,
                // Signup is restricted to the university domain; sign-in accepts
                // any address, because admins create accounts manually with
                // Gmail/Outlook/etc. and those users must be able to log in.
                hint: _mode == AuthMode.signup
                    ? l10n.emailHint(AppConfig.primaryEmailDomain)
                    : null,
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                forceLtr: true,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email,
                ],
                validator: (v) => _mode == AuthMode.signup
                    ? Validators.universityEmail(l10n, v)
                    : Validators.email(l10n, v),
              ),
              if (_showPasswordField) ...[
                const SizedBox(height: 12),
                AuthTextField(
                  controller: _passwordController,
                  label: l10n.fieldPassword,
                  hint: _mode == AuthMode.signup
                      ? l10n.fieldPasswordSignupHint
                      : null,
                  icon: Icons.lock_outline,
                  obscureText: true,
                  autofillHints: [
                    _mode == AuthMode.signup
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  validator: (v) => Validators.password(l10n, v),
                ),
              ],
              if (_mode == AuthMode.signup) ...[
                const SizedBox(height: 12),
                AuthTextField(
                  controller: _confirmController,
                  label: l10n.fieldConfirmPassword,
                  icon: Icons.lock_outline,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) => Validators.confirmPassword(
                    l10n,
                    v,
                    _passwordController.text,
                  ),
                ),
              ],
              if (state.errorKind != null &&
                  state.errorKind != AuthErrorKind.blockedUser) ...[
                const SizedBox(height: 12),
                InlineBanner(
                  message: state.errorKind!.message(l10n),
                  tone: BannerTone.error,
                ),
              ],
              const SizedBox(height: 20),
              PrimaryGradientButton(
                label: buttonLabel,
                loading: state.loading,
                onPressed: () => _submit(l10n),
              ),
              if (_mode == AuthMode.login &&
                  _method == LoginMethod.password) ...[
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.forgotPassword),
                    child: Text(l10n.linkForgotPassword),
                  ),
                ),
              ],
              // Only relevant while registering — sign-in has no domain rule.
              if (_mode == AuthMode.signup) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.domainNote(AppConfig.allowedEmailDomainsLabel),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedForeground,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
