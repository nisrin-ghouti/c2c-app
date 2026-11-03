import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/benefits/presentation/screens/benefits_screen.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/screens/complete_profile_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/policy_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/student_app_restricted_screen.dart';
import '../../features/auth/presentation/screens/verify_otp_screen.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/events/presentation/screens/event_by_id_screen.dart';
import '../../features/events/presentation/screens/event_list_screen.dart';
import '../../features/events/presentation/screens/my_events_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/matches/presentation/screens/matches_screen.dart';
import '../../features/onboarding/presentation/screens/language_selection_screen.dart';
import '../../features/points/presentation/screens/scanning_screen.dart';
import '../../features/profile/presentation/screens/my_profile_screen.dart';
import '../../features/roles/presentation/providers/roles_providers.dart';
import '../../features/surveys/presentation/screens/surveys_list_screen.dart';
import '../localization/locale_controller.dart';
import 'app_routes.dart';
import 'app_shell.dart';
import 'deep_link_service.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // The GoRouter is built ONCE and kept stable. We deliberately do NOT
  // `ref.watch` here — recreating the router on every auth/profile change and
  // reading providers inside `redirect` races with Riverpod's rebuild cycle
  // ("Cannot use ref functions after the dependency of a provider changed").
  // Instead a `refreshListenable` re-runs `redirect` when the relevant
  // providers change, and `redirect` reads their current values via `ref.read`.
  final refresh = _RouterRefreshNotifier(ref, [
    hasChosenLanguageProvider,
    authSessionProvider,
    profileGateProvider,
    isStudentEligibleProvider,
  ]);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    // Safety net if a custom-scheme URI still reaches GoRouter as a location
    // (e.g. before flutter_deeplinking_enabled=false ships). Prefer
    // DeepLinkService; this only recovers instead of showing a blank error.
    onException: (context, state, router) {
      final eventId = DeepLinkService.eventIdFromLink(state.uri);
      if (eventId != null) {
        router.go(AppRoutes.eventById(eventId));
        return;
      }
      debugPrint('GoRouter onException: ${state.uri}');
      router.go(AppRoutes.home);
    },
    redirect: (context, state) {
      final location = state.matchedLocation;
      final hasChosenLanguage = ref.read(hasChosenLanguageProvider);

      if (!hasChosenLanguage) {
        return location == AppRoutes.language ? null : AppRoutes.language;
      }
      if (location == AppRoutes.language) return AppRoutes.home;

      // The password-recovery link signs the user into a short-lived
      // session on this exact screen — never bounce it away.
      if (location == AppRoutes.resetPassword) return null;

      final isLoggedIn = ref.read(currentAuthSessionProvider).isAuthenticated;
      final isOnAuth = location.startsWith(AppRoutes.auth);
      if (!isLoggedIn && !isOnAuth) return AppRoutes.auth;
      if (isLoggedIn && isOnAuth) return AppRoutes.home;
      if (!isLoggedIn) return null;

      // Admin/Host-only accounts (no explicit student grant) have no
      // student-facing functionality at all — gate them here, ahead of
      // onboarding/profile/policy, so they never reach any part of the
      // student app. Mirrors `is_student_eligible`, the same rule already
      // enforced server-side for matching/points/benefits. Fails open like
      // `profileGateProvider` below until it resolves, to avoid flashing
      // the block screen for eligible users on a cold start.
      final isStudentEligible = ref.read(isStudentEligibleProvider).valueOrNull;
      if (isStudentEligible == false) {
        return location == AppRoutes.studentAppRestricted
            ? null
            : AppRoutes.studentAppRestricted;
      }
      if (location == AppRoutes.studentAppRestricted) return AppRoutes.home;
      // Completion/policy status needs an async fetch. Until it resolves we
      // fail open (don't block) to avoid flashing a gate screen; the router
      // re-runs automatically once `profileGateProvider` loads.
      final gate = ref.read(profileGateProvider).valueOrNull;
      if (gate != null) {
        if (!gate.profileComplete) {
          return location == AppRoutes.completeProfile
              ? null
              : AppRoutes.completeProfile;
        }
        // Complete now — don't strand the user on the completion screen.
        if (location == AppRoutes.completeProfile) return AppRoutes.home;

        if (!gate.policyAgreed) {
          return location == AppRoutes.policy ? null : AppRoutes.policy;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.language,
        builder: (_, _) => const LanguageSelectionScreen(),
      ),
      GoRoute(path: AppRoutes.auth, builder: (_, _) => const AuthScreen()),
      GoRoute(
        path: AppRoutes.verifyOtp,
        builder: (_, state) => VerifyOtpScreen(email: state.extra as String),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (_, _) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.completeProfile,
        builder: (_, _) => const CompleteProfileScreen(),
      ),
      GoRoute(path: AppRoutes.policy, builder: (_, _) => const PolicyScreen()),
      GoRoute(
        path: AppRoutes.studentAppRestricted,
        builder: (_, _) => const StudentAppRestrictedScreen(),
      ),
      GoRoute(
        path: AppRoutes.events,
        builder: (_, _) => const EventListScreen(),
      ),
      GoRoute(
        path: AppRoutes.eventsNextMonth,
        builder: (_, _) => const EventListScreen(onlyNextThirtyDays: true),
      ),
      GoRoute(
        path: AppRoutes.eventByIdPattern,
        builder: (_, state) =>
            EventByIdScreen(eventId: state.pathParameters['eventId']!),
      ),
      GoRoute(
        path: AppRoutes.myEvents,
        builder: (_, _) => const MyEventsScreen(),
      ),
      GoRoute(path: AppRoutes.chats, builder: (_, _) => const ChatListScreen()),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.surveys,
        builder: (_, _) => const SurveysListScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.matches,
                builder: (_, _) => const MatchesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.connect,
                builder: (_, _) => const ScanningScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.benefits,
                builder: (_, _) => const BenefitsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, _) => const MyProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Bridges Riverpod providers to go_router's [GoRouter.refreshListenable].
/// Notifies (re-running the router's `redirect`) whenever any of the watched
/// providers changes, without recreating the router or reading providers from
/// a stale element.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref, List<ProviderListenable<Object?>> providers) {
    _subscriptions = [
      for (final provider in providers)
        ref.listen(provider, (_, _) => notifyListeners()),
    ];
  }

  late final List<ProviderSubscription<Object?>> _subscriptions;

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.close();
    }
    super.dispose();
  }
}
