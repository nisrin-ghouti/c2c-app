import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/accessibility/accessibility_controller.dart';
import 'core/accessibility/accessibility_settings.dart';
import 'core/l10n/generated/app_localizations.dart';
import 'core/localization/locale_controller.dart';
import 'core/push/push_service.dart';
import 'core/routing/app_router.dart';
import 'core/routing/app_routes.dart';
import 'core/routing/deep_link_service.dart';
import 'core/storage/shared_preferences_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/root_scaffold_messenger.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/onboarding/presentation/controllers/guided_matching_tour_controller.dart';
import 'features/onboarding/presentation/controllers/tour_resume_controller.dart';

/// Guards [attemptTourResume] to only ever run once per app process — it's
/// triggered from `build()` (no reliable single-shot hook exists this high
/// up in a stateless `ConsumerWidget`), so this flag stands in for the
/// `initState`-once semantics a `ConsumerStatefulWidget` would give for free.
bool _tourResumeAttempted = false;

class C2CApp extends ConsumerStatefulWidget {
  const C2CApp({super.key});

  @override
  ConsumerState<C2CApp> createState() => _C2CAppState();
}

class _C2CAppState extends ConsumerState<C2CApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Re-check the block on resume.
    //
    // The realtime socket is dropped while the app is backgrounded, so a
    // block applied during that window produces no event — the subscription
    // simply reconnects and carries on. Invalidating forces the stream to be
    // rebuilt, and its initial fetch is what catches a block that landed
    // while nobody was listening. Without this, "blocked while backgrounded"
    // stayed undetected until the process was killed.
    ref.invalidate(currentUserBanProvider);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeControllerProvider);
    final accessibility = ref.watch(accessibilitySettingsProvider);

    // Eagerly build the push service (runs one-time init: permission, foreground
    // display, tap routing) and (re)register this device's FCM token whenever a
    // user signs in.
    ref.watch(pushServiceProvider);

    // Same shape: build the deep-link service eagerly so a shared event link
    // that cold-started the app is picked up (`getInitialLink`) and later ones
    // keep arriving on its stream.
    ref.watch(deepLinkServiceProvider);
    ref.listen(authSessionProvider, (previous, next) {
      final signedIn = next.valueOrNull?.userId != null;
      if (signedIn) ref.read(pushServiceProvider).registerToken();
    });

    // Push copy is rendered server-side per device from the language this
    // device last reported (`device_tokens.language`, migration 0075). The FCM
    // token doesn't change when the user switches language, so nothing else
    // would push the new value and every push would keep arriving in the old
    // one until the next sign-in.
    ref.listen(localeControllerProvider, (previous, next) {
      if (previous == next) return;
      ref.read(pushServiceProvider).syncLanguage();
    });

    // Persist the guided-matching tour's current step (for exact-step resume
    // after a refresh — the Home segment's own steps are persisted directly
    // from `main.dart` instead, since they're driven by `ShowcaseView`
    // callbacks rather than this provider).
    ref.listen<MatchingTourStep>(matchingTourStepProvider, (previous, next) {
      ref
          .read(appPreferencesProvider)
          .setTourResumeStep(
            next == MatchingTourStep.none ? null : 'matching.${next.name}',
          );
    });

    if (!_tourResumeAttempted) {
      _tourResumeAttempted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) attemptTourResume(context, router);
      });
    }
    ref.listen(currentUserBanProvider, (previous, next) async {
      final isBanned = next.valueOrNull ?? false;

      if (isBanned) {
        await ref.read(signOutProvider)();
      }
    });
    // The password-reset email link can land the user anywhere in the
    // navigation stack (or cold-start the app); once Supabase exchanges it
    // for a recovery session, always force them to the reset screen.
    ref.listen(passwordRecoveryEventsProvider, (previous, next) {
      if (next is AsyncData<void>) {
        router.go(AppRoutes.resetPassword);
      }
    });
    return MaterialApp.router(
      title: 'C2C',
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light(locale.languageCode),
      // Every screen in this app is built against the light-mode design
      // (all reference screenshots are light). `AppTheme.dark` only themes
      // a handful of ColorScheme values — most widgets read the static
      // `AppColors` constants directly rather than `Theme.of(context)`, so
      // following the system's dark mode produced a broken half-dark/
      // half-light screen instead of an actual dark design. Force light
      // until a real dark theme (touching every widget) is built.
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) {
        Widget result = MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(accessibility.textScale.multiplier),
          ),
          child: child!,
        );
        if (accessibility.highContrast) {
          // AppColors are hardcoded constants (not theme-resolved), so
          // per-widget color swapping isn't feasible without a much larger
          // refactor — a global contrast-boost filter is the pragmatic
          // app-wide equivalent, applied at the same `builder` level the
          // plan calls for.
          result = ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              1.4,
              0,
              0,
              0,
              -40,
              0,
              1.4,
              0,
              0,
              -40,
              0,
              0,
              1.4,
              0,
              -40,
              0,
              0,
              0,
              1,
              0,
            ]),
            child: result,
          );
        }
        return result;
      },
    );
  }
}
