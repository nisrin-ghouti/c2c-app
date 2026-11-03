import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/widgets/primary_gradient_button.dart';
import '../controllers/onboarding_tutorial_controller.dart';

class _Slide {
  const _Slide({
    required this.emoji,
    required this.titleOf,
    required this.bodyOf,
  });

  final String emoji;
  final String Function(AppLocalizations l10n) titleOf;
  final String Function(AppLocalizations l10n) bodyOf;
}

final _slides = [
  _Slide(
    emoji: '👋',
    titleOf: (l10n) => l10n.tutorialWelcomeTitle,
    bodyOf: (l10n) => l10n.tutorialWelcomeBody,
  ),
  _Slide(
    emoji: '🤝',
    titleOf: (l10n) => l10n.tutorialMatchesTitle,
    bodyOf: (l10n) => l10n.tutorialMatchesBody,
  ),
  _Slide(
    emoji: '📷',
    titleOf: (l10n) => l10n.tutorialScanTitle,
    bodyOf: (l10n) => l10n.tutorialScanBody,
  ),
  _Slide(
    emoji: '🎁',
    titleOf: (l10n) => l10n.tutorialBenefitsTitle,
    bodyOf: (l10n) => l10n.tutorialBenefitsBody,
  ),
  _Slide(
    emoji: '🏆',
    titleOf: (l10n) => l10n.tutorialChampionsTitle,
    bodyOf: (l10n) => l10n.tutorialChampionsBody,
  ),
];

/// Shown once, the first time a signed-in user reaches the app (after
/// language + policy). Advance-only via the Next/Get Started button; going
/// back a slide is allowed, but there's no skip and the system back button
/// never exits the flow early — mirrors the plan's "advance-only via OK,
/// back allowed" rule.
class OnboardingTutorialScreen extends ConsumerStatefulWidget {
  const OnboardingTutorialScreen({super.key});

  @override
  ConsumerState<OnboardingTutorialScreen> createState() =>
      _OnboardingTutorialScreenState();
}

class _OnboardingTutorialScreenState
    extends ConsumerState<OnboardingTutorialScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (_page == 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _next() async {
    if (_page < _slides.length - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }
    await ref.read(onboardingTutorialControllerProvider.notifier).markSeen();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLast = _page == _slides.length - 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppGradients.hero),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (index) => setState(() => _page = index),
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              slide.emoji,
                              style: const TextStyle(fontSize: 72),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              slide.titleOf(l10n),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              slide.bodyOf(l10n),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _slides.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _page ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                  child: Row(
                    children: [
                      if (_page > 0)
                        TextButton(
                          onPressed: _goBack,
                          child: Text(l10n.tutorialBackAction),
                        )
                      else
                        const SizedBox.shrink(),
                      const Spacer(),
                      SizedBox(
                        width: 160,
                        child: PrimaryGradientButton(
                          label: isLast
                              ? l10n.tutorialGetStartedAction
                              : l10n.tutorialNextAction,
                          onPressed: _next,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
