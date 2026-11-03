import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart' show supabase;
import '../localization/locale_controller.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';

/// Action id for the inline "Reply" action on chat-message notifications, and
/// the iOS notification category it's registered under — must match the
/// `apns.payload.aps.category` string the `send-push` Edge Function sets.
const _replyActionId = 'reply_new_message';
const _newMessageCategoryId = 'NEW_MESSAGE_CATEGORY';

/// The Android channel our notifications post to — referenced by the same id
/// (`c2c_default`) the Edge Function sets on outgoing FCM messages.
const _androidChannel = AndroidNotificationChannel(
  'c2c_default',
  'General',
  description: 'C2C notifications',
  importance: Importance.high,
);

/// Background/terminated-isolate message handler. Must be a top-level function
/// annotated `vm:entry-point` so it survives tree-shaking and can run in its
/// own isolate.
///
/// Every type except Android `new_message` carries a `notification` block, so
/// the OS shows those in the system tray automatically and there's nothing to
/// do here. Android `new_message` pushes are data-only instead (so a "Reply"
/// action can be attached — the OS can't add custom actions to a notification
/// it auto-displays), so for those we build and show the notification
/// ourselves, with the reply action wired up.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  if (message.data['type'] != 'new_message') return;

  WidgetsFlutterBinding.ensureInitialized();
  await FlutterLocalNotificationsPlugin().show(
    id: message.hashCode,
    // `notif_title`/`notif_body` are the strings `send-push` already resolved
    // in this device's reported language (see `device_tokens.language`,
    // migration 0075). This isolate has no `AppLocalizations`, so without them
    // the only option was hardcoded English.
    title:
        message.data['sender_name'] as String? ??
        message.data['notif_title'] as String? ??
        'New message',
    body:
        message.data['preview'] as String? ??
        message.data['notif_body'] as String? ??
        'sent you a message',
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChannel.id,
        _androidChannel.name,
        channelDescription: _androidChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        actions: [
          AndroidNotificationAction(
            _replyActionId,
            'Reply',
            inputs: [AndroidNotificationActionInput(label: 'Type a message…')],
            semanticAction: SemanticAction.reply,
          ),
        ],
      ),
    ),
    payload: jsonEncode(message.data),
  );
}

/// Handles the "Reply" notification action. Fires in a background
/// isolate/engine on both platforms and in every app state (foreground,
/// backgrounded, or killed) — actions without `showsUserInterface` always
/// route here rather than to the running app. Must be top-level +
/// `vm:entry-point` for the same reason as [firebaseMessagingBackgroundHandler].
///
/// This isolate shares no state with the main one (no `ProviderScope`, no
/// already-initialized Supabase client), so it re-initializes its own —
/// the default `SharedPreferences`-backed session persistence restores
/// whatever session was already signed in.
@pragma('vm:entry-point')
Future<void> notificationBackgroundHandler(
  NotificationResponse response,
) async {
  if (response.actionId != _replyActionId) return;
  final reply = response.input?.trim();
  if (reply == null || reply.isEmpty) return;

  final payload = response.payload;
  if (payload == null || payload.isEmpty) return;

  String? chatId;
  try {
    final data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
    chatId = data['chat_id'] as String?;
  } catch (_) {
    return;
  }
  if (chatId == null) return;

  try {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load();
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    await Supabase.instance.client.rpc(
      'send_message',
      params: {'_chat_id': chatId, '_body': reply},
    );
  } catch (e) {
    // No UI reachable from here — a failed reply (expired session, no
    // network) just silently doesn't send. Logged for local debugging only.
    debugPrint('PushService: background reply failed: $e');
  }
}

/// Owns the device-side push lifecycle: permission, the FCM token (registered
/// against the signed-in user), foreground display, and tap-to-open routing.
///
/// Push delivery itself is server-side (the `send-push` Edge Function → FCM);
/// this class is only the client half.
class PushService {
  PushService(this._router, this._languageCode);

  final GoRouter _router;

  /// Reads the app's currently selected language. A callback rather than a
  /// value so a locale change after construction is picked up by the next
  /// [registerToken] — the service outlives any one locale.
  final String Function() _languageCode;

  final _local = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String? _lastToken;

  /// One-time setup: permission, local-notification plugin + channel, and the
  /// foreground / tap listeners. Also registers the token if a session is
  /// already restored (cold start while logged in).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint(
        'PushService: notification permission denied by user; no push will be shown.',
      );
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit = DarwinInitializationSettings(
      notificationCategories: [
        DarwinNotificationCategory(
          _newMessageCategoryId,
          actions: [
            DarwinNotificationAction.text(
              _replyActionId,
              'Reply',
              buttonTitle: 'Send',
              placeholder: 'Type a message…',
            ),
          ],
        ),
      ],
    );
    await _local.initialize(
      settings: InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload != null && payload.isNotEmpty) {
          _routeFromData(Map<String, dynamic>.from(jsonDecode(payload) as Map));
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    // Foreground messages aren't shown by the OS — display them ourselves.
    FirebaseMessaging.onMessage.listen(_showForeground);

    // Tap handling: while backgrounded, and the tap that cold-started the app.
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _routeFromData(m.data));
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _routeFromData(initial.data);

    FirebaseMessaging.instance.onTokenRefresh.listen(_saveToken);

    if (supabase.auth.currentUser != null) await registerToken();
  }

  /// Fetches and stores this device's FCM token for the current user. Safe to
  /// call repeatedly (the RPC upserts).
  Future<void> registerToken() async {
    final token = await _fetchToken();
    if (token != null) await _saveToken(token);
  }

  /// Resolves the FCM token, or null if this device can't have one right now.
  ///
  /// iOS is the reason this isn't just `getToken()`: Firebase won't issue an
  /// FCM token until APNs has handed it a device token, and APNs registration
  /// lags app start by a beat. Calling `getToken()` straight away — as this
  /// did — throws `apns-token-not-set`, and since [init] is kicked off
  /// unawaited from `pushServiceProvider`, that throw disappears into a dead
  /// future and the device stays unregistered (no `device_tokens` row, so
  /// `send-push` finds nothing to send to) until the next sign-in happens to
  /// catch a better moment. Android has no such handshake and never hit this.
  Future<String?> _fetchToken() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint(
          'PushService: notifications denied; iOS issues no APNs token.',
        );
        return null;
      }
      if (await _awaitApnsToken() == null) {
        debugPrint(
          'PushService: no APNs token yet; skipping token registration.',
        );
        return null;
      }
    }
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('PushService: getToken failed: $e');
      return null;
    }
  }

  /// Polls for the APNs device token, which arrives asynchronously after
  /// `registerForRemoteNotifications` — and not at all until apsd has a live
  /// connection to Apple. On a weak or intermittent link that handshake can
  /// take tens of seconds, so the window here is deliberately generous
  /// (~40s of backing-off retries): giving up early leaves the device with no
  /// `device_tokens` row at all, which is silent and lasts until the next
  /// sign-in. This runs unawaited off [init], so waiting costs nothing.
  Future<String?> _awaitApnsToken() async {
    for (var attempt = 0; attempt < 15; attempt++) {
      try {
        final apns = await FirebaseMessaging.instance.getAPNSToken();
        if (apns != null) return apns;
      } catch (e) {
        debugPrint('PushService: getAPNSToken failed: $e');
      }
      final backoff = (500 * (attempt + 1)).clamp(500, 3000);
      await Future<void>.delayed(Duration(milliseconds: backoff));
    }
    return null;
  }

  Future<void> _saveToken(String token) async {
    if (supabase.auth.currentUser == null) return;
    _lastToken = token;
    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : 'android';
    try {
      await supabase.rpc(
        'register_device_token',
        params: {
          '_token': token,
          '_platform': platform,
          // What `send-push` builds this device's copy from, so a push reads
          // in the language the student chose rather than the one the
          // organizer typed. See migration 0075.
          '_language': _languageCode(),
        },
      );
    } catch (e) {
      // Non-fatal: a failed registration just means no push until next attempt.
      debugPrint('PushService: register_device_token failed: $e');
    }
  }

  /// Re-reports this device's language without waiting for a new FCM token.
  ///
  /// Called when the user changes the app language: the token itself hasn't
  /// changed, so nothing else would have pushed the new value, and until it
  /// does every push keeps arriving in the previous language.
  Future<void> syncLanguage() async {
    if (supabase.auth.currentUser == null) return;
    final token = _lastToken;
    // No token cached yet means registration hasn't happened at all; that will
    // report the current language itself when it does.
    if (token == null) return;
    await _saveToken(token);
  }

  /// Call *before* signing out so this device stops receiving the user's
  /// pushes (the RPC needs the auth context, which is gone after sign-out).
  Future<void> unregisterToken() async {
    String? token;
    try {
      token = _lastToken ?? await FirebaseMessaging.instance.getToken();
    } catch (_) {
      // getToken() can throw where messaging isn't fully set up (e.g. web
      // without a registered service worker) — sign-out must proceed either way.
      return;
    }
    if (token == null) return;
    try {
      await supabase.rpc('unregister_device_token', params: {'_token': token});
    } catch (_) {}
  }

  void _showForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    final isNewMessage = message.data['type'] == 'new_message';
    _local.show(
      id: n.hashCode,
      title: n.title,
      body: n.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: isNewMessage ? _newMessageCategoryId : null,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Sends the user to the most relevant screen for a tapped notification.
  /// The payload only carries ids, so we open the list screen for each area
  /// rather than a specific record (the lists are cheap and self-navigating).
  void _routeFromData(Map<String, dynamic> data) {
    switch (data['type'] as String?) {
      case 'new_message':
        _router.push(AppRoutes.chats);
      case 'event_published':
      case 'event_pending_approval':
      case 'event_decision':
        _router.push(AppRoutes.events);
      case 'benefit_redeemed':
      case 'benefit_published':
        _router.push(AppRoutes.benefits);
      case 'survey_published':
        _router.push(AppRoutes.surveys);
      // Reminders are about one specific event, and the payload carries its
      // id, so these are the one case that can open the record itself rather
      // than a list. Falls back to the events list if the id is missing.
      case 'event_reminder_tomorrow':
      case 'event_reminder_today':
        final eventId = data['event_id'] as String?;
        _router.push(
          eventId == null || eventId.isEmpty
              ? AppRoutes.events
              : AppRoutes.eventById(eventId),
        );
      default:
        _router.push(AppRoutes.notifications);
    }
  }
}

/// App-wide push service, bound to the router so taps can navigate. Reading it
/// the first time kicks off [PushService.init].
final pushServiceProvider = Provider<PushService>((ref) {
  final service = PushService(
    ref.watch(appRouterProvider),
    // `ref.read` inside a callback, not `ref.watch`: watching the locale here
    // would rebuild the service (and re-run `init`) on every language change.
    // The callback reads the current value whenever a token is registered.
    () => ref.read(localeControllerProvider).languageCode,
  );
  service.init();
  return service;
});
