import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/presentation/providers/chat_providers.dart';
import '../../features/notifications/presentation/providers/notifications_providers.dart';
import '../l10n/generated/app_localizations.dart';
import '../routing/app_routes.dart';
import 'app_logo.dart';

/// The "C2C logo + chat + bell icons, screen title" header shared by
/// Matches, Scanning & Points, and Monthly Champions — kept as one widget
/// so all three stay visually identical instead of drifting apart.
class AppHeaderBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppHeaderBar({super.key, required this.title, this.leading});

  final String title;

  /// Optional leading widget (e.g. a "back" link on Monthly Champions).
  final Widget? leading;

  static void showComingSoon(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.comingSoon)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final unreadChats = ref.watch(unreadChatsCountProvider).valueOrNull ?? 0;
    final unreadNotifications =
        ref.watch(unreadNotificationsCountProvider).valueOrNull ?? 0;

    return AppBar(
      leading: leading,
      // Let Flutter add a back button whenever there's something to pop.
      // Bottom-nav tabs (Matches, Scan, Benefits, Profile) sit at the root of
      // their branch so `canPop()` is false and no arrow appears; pushed
      // screens like Events and My Events get one automatically.
      automaticallyImplyLeading: true,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      actions: [
        // Tapping the logo always returns to Home — `go` (not `push`) so it
        // switches the bottom-nav branch rather than stacking a second Home
        // on top of the current tab.
        Semantics(
          button: true,
          label: l10n.navHome,
          child: InkWell(
            onTap: () => context.go(AppRoutes.home),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: AppLogo(height: 26),
            ),
          ),
        ),
        IconButton(
          // Badge wraps just the icon glyph (not the whole button, which
          // has a much bigger tap-target box) so it sits right at the
          // icon's corner instead of floating far off in the button's
          // padding.
          icon: Badge(
            label: Text('$unreadChats'),
            isLabelVisible: unreadChats > 0,
            offset: const Offset(2, -2),
            child: const Icon(Icons.chat_bubble_outline),
          ),
          onPressed: () => context.push(AppRoutes.chats),
        ),
        IconButton(
          icon: Badge(
            label: Text('$unreadNotifications'),
            isLabelVisible: unreadNotifications > 0,
            offset: const Offset(2, -2),
            child: const Icon(Icons.notifications_outlined),
          ),
          onPressed: () => context.push(AppRoutes.notifications),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
