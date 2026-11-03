import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/push/push_service.dart';
import 'core/storage/app_preferences.dart';
import 'core/storage/shared_preferences_provider.dart';
import 'features/onboarding/presentation/home_coach_mark_keys.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Push: init Firebase and register the background message handler before the
  // app starts. The device-side lifecycle (token, foreground, taps) is owned by
  // PushService, wired up in C2CApp once the router exists.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final prefs = await SharedPreferences.getInstance();
  final appPreferences = AppPreferences(prefs);

  // Home coach-mark tour — a global registration is enough (no wrapping
  // widget needed since v5); `HomeScreen` starts it on first real visit.
  ShowcaseView.register(enableAutoScroll: true);

  // Persist which Home tour sub-step is active, for exact-step resume after
  // a refresh (`attemptTourResume`). Registered once here — outside Riverpod
  // and outside any widget lifecycle — since `ShowcaseView`'s callback list
  // isn't deduplicated the way `ref.listen` is when called from `build()`.
  ShowcaseView.get().addOnStartCallback((index, key) {
    for (final entry in homeTourStepOrder) {
      if (entry.value == key) {
        appPreferences.setTourResumeStep('home.${entry.key}');
        return;
      }
    }
  });

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const C2CApp(),
    ),
  );
}

/// Global accessor — use this everywhere in the app instead of re-fetching
/// `Supabase.instance.client`.
final supabase = Supabase.instance.client;
