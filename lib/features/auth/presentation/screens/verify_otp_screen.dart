import 'dart:async';

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
import '../controllers/verify_otp_controller.dart';
import '../navigation/post_auth_navigation.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(text: widget.email);
  final _otpController = TextEditingController();

  /// Supabase enforces a minimum interval between auth emails to the same
  /// address (Authentication → Emails → SMTP, default 60s). Resending sooner
  /// is silently dropped, so mirror the limit in the UI instead of letting the
  /// user tap a button that does nothing.
  static const _resendCooldown = Duration(seconds: 60);

  Timer? _cooldownTimer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    // A code was just sent to get the user here, so the cooldown starts now.
    _startCooldown();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _secondsLeft = _resendCooldown.inSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(verifyOtpControllerProvider.notifier);
    final destination = await controller.verify(
      email: _emailController.text.trim().toLowerCase(),
      token: _otpController.text.trim(),
    );
    if (!mounted || destination == null) return;
    context.goToPostAuthDestination(destination);
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0) return;
    final sent = await ref
        .read(verifyOtpControllerProvider.notifier)
        .resend(_emailController.text.trim().toLowerCase());
    // Only lock the button when a code actually went out.
    if (sent && mounted) _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(verifyOtpControllerProvider);

    return AuthScaffold(
      title: l10n.verifyTitle,
      subtitle: l10n.verifySubtitle,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sits directly under `verifySubtitle` ("we sent a 6-digit code to
            // your email"), which is the confirmation that a code went out —
            // reaching this screen at all means one just did, so the note
            // needs no separate trigger. The resend banner below renders
            // between the fields and leaves this in place.
            const SpamFolderNote(),
            const SizedBox(height: 16),
            AuthTextField(
              controller: _emailController,
              label: l10n.fieldEmail,
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              forceLtr: true,
              validator: (v) => Validators.email(l10n, v),
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _otpController,
              label: '',
              hint: l10n.otpHint,
              maxLength: 6,
              keyboardType: TextInputType.number,
              forceLtr: true,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                letterSpacing: 10,
                fontWeight: FontWeight.w700,
              ),
              validator: (v) => Validators.otp(l10n, v),
              onFieldSubmitted: (_) => _verify(),
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
              label: l10n.buttonVerify,
              loading: state.loading,
              onPressed: _verify,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: (state.loading || _secondsLeft > 0) ? null : _resend,
                child: Text(
                  _secondsLeft > 0
                      ? l10n.linkResendIn(_secondsLeft)
                      : l10n.linkResend,
                ),
              ),
            ),
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
