import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/auth_scaffold.dart';
import '../../../../core/widgets/auth_text_field.dart';
import '../../../../core/widgets/inline_banner.dart';
import '../../../../core/widgets/primary_gradient_button.dart';
import '../widgets/spam_folder_note.dart';
import '../controllers/auth_message_kind.dart';
import '../controllers/forgot_password_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(forgotPasswordControllerProvider.notifier)
        .submit(_emailController.text.trim().toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(forgotPasswordControllerProvider);

    return AuthScaffold(
      title: l10n.forgotTitle,
      subtitle: l10n.forgotSubtitle,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              controller: _emailController,
              label: l10n.fieldEmail,
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              forceLtr: true,
              validator: (v) => Validators.email(l10n, v),
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
              // Only once the mail has actually gone out — unlike the verify
              // screen, reaching this one doesn't mean anything was sent yet.
              const SizedBox(height: 10),
              const SpamFolderNote(),
            ],
            const SizedBox(height: 20),
            PrimaryGradientButton(
              label: l10n.buttonSendResetLink,
              loading: state.loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () => context.go(AppRoutes.auth),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: Text(l10n.linkBackToLogin),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
