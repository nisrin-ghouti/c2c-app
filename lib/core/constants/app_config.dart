import 'package:flutter/foundation.dart' show kDebugMode;

/// App-wide constants that aren't secrets (those live in `.env`).
abstract final class AppConfig {
  /// The university domain student self-registration is meant to use.
  /// Centralized here so validators and localized copy never drift apart.
  ///
  /// Deliberately NOT applied to sign-in: admins create accounts manually
  /// with any address (Gmail, Outlook, …) and those users must be able to log
  /// in — see `Validators.email` vs `Validators.universityEmail`.
  static const primaryEmailDomain = 'mail.tau.ac.il';

  /// Domains accepted for **student self-registration**.
  ///
  /// `'gmail.com'` is only allowed in debug builds, so the team can test
  /// registration without a university address — release builds (what ships
  /// to the Play Store) enforce `@mail.tau.ac.il` only, per spec.
  ///
  /// Admins create any-email accounts through the separate `create_user` admin
  /// flow, which is not gated by this list.
  static List<String> get allowedEmailDomains => <String>[
    primaryEmailDomain,
    if (kDebugMode) 'gmail.com',
  ];

  /// Human-readable list for the "only these domains may register" copy.
  static String get allowedEmailDomainsLabel => allowedEmailDomains.join(' / ');

  static bool isAllowedEmail(String email) {
    final normalized = email.trim().toLowerCase();
    return allowedEmailDomains.any((domain) => normalized.endsWith('@$domain'));
  }

  /// Custom URL scheme the app registers natively (see AndroidManifest.xml's
  /// `MainActivity` intent-filter and Info.plist's `CFBundleURLTypes`) —
  /// must match the reverse-DNS bundle/application id exactly.
  static const _urlScheme = 'com.c2c.connecttocollect';

  /// Where Supabase redirects the user after they tap the "reset password"
  /// email link. The OS hands this URL to *this app* (instead of a browser)
  /// because of the native scheme registration above; supabase_flutter then
  /// picks it up automatically (`detectSessionInUri`, on by default) and
  /// fires an `AuthChangeEvent.passwordRecovery`.
  ///
  /// This exact URL must also be added to the Supabase dashboard under
  /// Authentication → URL Configuration → Redirect URLs, or Supabase will
  /// reject it and silently fall back to its default site URL.
  static const passwordResetRedirectUrl = '$_urlScheme://reset-password';

  /// Firebase Hosting site for this project — the same one that already serves
  /// the partner benefit-redemption page (`/r/<token>`, see
  /// `DigitalCard.qrValue` and `firebase.json`). Reused rather than
  /// introducing a second public host.
  static const webBaseUrl = 'https://connecttocollect-858b6.web.app';

  /// The public, shareable link for one event.
  ///
  /// An https URL rather than the `$_urlScheme://` deep link because this is
  /// pasted into WhatsApp/email/SMS: a custom scheme isn't recognised as a
  /// link by most of them, and it dead-ends for anyone without the app.
  /// `/e/<id>` is served by `web-redeem/public/event.html`, which hands off
  /// to [eventDeepLink] when the app is installed and offers the store
  /// listings when it isn't.
  ///
  /// The link carries only the event id. Whether its content is visible is
  /// decided server-side when the app opens it, by the same RLS and
  /// `visibility` rules as any other read — so forwarding a link to someone
  /// an event isn't for shows them nothing.
  static String eventShareUrl(String eventId) => '$webBaseUrl/e/$eventId';

  /// The in-app destination `/e/<id>` hands off to. Registered natively
  /// alongside [passwordResetRedirectUrl] (same scheme, so no new
  /// intent-filter or `CFBundleURLTypes` entry is needed) and handled by
  /// `DeepLinkService`.
  static String eventDeepLink(String eventId) => '$_urlScheme://events/$eventId';

  /// Host of [webBaseUrl], for matching an incoming https link.
  static const webHost = 'connecttocollect-858b6.web.app';
}
