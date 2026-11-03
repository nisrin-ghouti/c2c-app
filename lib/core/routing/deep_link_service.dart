import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_config.dart';
import 'app_router.dart';
import 'app_routes.dart';

/// Routes links opened from outside the app.
///
/// Two shapes reach us, and both mean the same thing:
///
///   * `com.c2c.connecttocollect://events/<id>` — the native scheme already
///     registered for password recovery (see `AppConfig.passwordResetRedirectUrl`
///     and the `MainActivity` intent-filter / `CFBundleURLTypes`). This is what
///     the `/e/<id>` web page hands off to when the app is installed.
///   * `https://connecttocollect-858b6.web.app/e/<id>` — the shareable link
///     itself, which only reaches the app on a device where the domain has been
///     verified (Android App Links / iOS Universal Links). Handled here too so
///     that enabling verification later needs no Dart change; until then the web
///     page does the handoff and this branch simply never fires.
///
/// Supabase's own auth links are deliberately left alone: `supabase_flutter`
/// consumes those itself (`detectSessionInUri`), and `passwordRecoveryEventsProvider`
/// already routes the result. Anything this class doesn't recognise is ignored
/// rather than guessed at.
///
/// Routing only — it pushes [AppRoutes.eventById] and lets that screen fetch the
/// event. Whether the viewer may see it is decided server-side by the same RLS
/// and `visibility` rules as any other read, so a forwarded link can't expose a
/// private event.
class DeepLinkService {
  DeepLinkService(this._router);

  final GoRouter _router;
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Links that arrive while the app is already running.
    _subscription = _appLinks.uriLinkStream.listen(
      _handle,
      onError: (Object e) => debugPrint('DeepLinkService: link stream error: $e'),
    );

    // The link that cold-started the app, if any.
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handle(initial);
    } catch (e) {
      debugPrint('DeepLinkService: getInitialLink failed: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _handle(Uri uri) {
    final eventId = eventIdFromLink(uri);
    if (eventId == null) return;
    _router.push(AppRoutes.eventById(eventId));
  }

  /// The event id in [uri], or null if it isn't an event link.
  ///
  /// Exposed (and pure) so the parsing is testable without a router or the
  /// platform channel behind `app_links`.
  @visibleForTesting
  static String? eventIdFromLink(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    // com.c2c.connecttocollect://events/<id> — the host carries the first
    // path component for a custom scheme, so "events" arrives as `host`.
    // Also accept close variants some platforms emit (e.g. a truncated
    // scheme that still ends with connecttocollect).
    final isAppScheme = uri.scheme == 'com.c2c.connecttocollect' ||
        uri.scheme.endsWith('connecttocollect');
    if (isAppScheme) {
      if (uri.host == 'events' && segments.length == 1) return segments.first;
      // Tolerate the `scheme:///events/<id>` spelling (empty authority),
      // which some senders produce.
      if (uri.host.isEmpty &&
          segments.length == 2 &&
          segments.first == 'events') {
        return segments[1];
      }
      return null;
    }

    // https://<webHost>/e/<id>
    if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host == AppConfig.webHost &&
        segments.length == 2 &&
        segments.first == 'e') {
      return segments[1];
    }
    return null;
  }
}

/// App-wide deep-link service, bound to the router so links can navigate.
/// Reading it the first time kicks off [DeepLinkService.init]; mirrors
/// `pushServiceProvider`.
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final service = DeepLinkService(ref.watch(appRouterProvider));
  service.init();
  ref.onDispose(service.dispose);
  return service;
});
