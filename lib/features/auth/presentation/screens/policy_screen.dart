import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/inline_banner.dart';
import '../../../../core/widgets/primary_gradient_button.dart';
import '../controllers/policy_controller.dart';
import '../providers/auth_providers.dart';

class PolicyScreen extends ConsumerWidget {
  const PolicyScreen({super.key});

  Future<void> _agree(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(agreeToPolicyControllerProvider.notifier).agree();
    if (!ok) return;
    // Refresh the router's completion gate before navigating so the (now
    // satisfied) redirect doesn't bounce the user back to this screen.
    ref.invalidate(profileGateProvider);
    await ref.read(profileGateProvider.future);
    if (!context.mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pageData = ref.watch(policyPageDataProvider);
    final agreeState = ref.watch(agreeToPolicyControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.policyTitle)),
      body: SafeArea(
        child: pageData.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(l10n.errorLoadPolicyFailed)),
          data: (data) {
            final policy = data.policy;
            final alreadyAgreed = data.alreadyAgreed;
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: policy == null
                        ? Text(l10n.policyNoneActive)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.policyVersionLabel(policy.version),
                                style: const TextStyle(
                                  color: AppColors.mutedForeground,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                policy.title,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 16),
                              Text(policy.body),
                            ],
                          ),
                  ),
                ),
                if (agreeState.errorKind != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: InlineBanner(
                      message: l10n.errorAgreePolicyFailed,
                      tone: BannerTone.error,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: PrimaryGradientButton(
                    label: alreadyAgreed
                        ? l10n.buttonAlreadyAgreed
                        : l10n.buttonAgree,
                    loading: agreeState.loading,
                    onPressed: (policy == null || alreadyAgreed)
                        ? null
                        : () => _agree(context, ref),
                  ),
                ),
                if (alreadyAgreed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.go(AppRoutes.home),
                        child: Text(l10n.buttonContinueToApp),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
