import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../domain/usecases/determine_post_auth_destination.dart';

/// Shared by every screen that can complete an auth flow (OTP verify,
/// password login, profile completion) so the "where do we send them next"
/// routing logic lives in exactly one place.
extension PostAuthNavigation on BuildContext {
  void goToPostAuthDestination(PostAuthDestination destination) {
    switch (destination) {
      case PostAuthDestination.completeProfile:
        go(AppRoutes.completeProfile);
      case PostAuthDestination.policy:
        go(AppRoutes.policy);
      case PostAuthDestination.home:
        go(AppRoutes.home);
    }
  }
}
