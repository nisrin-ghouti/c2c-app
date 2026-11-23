import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/storage/shared_preferences_provider.dart';

/// Clears a tour step saved by an older build.
///
/// That step used to reopen the guide after a refresh and route the student
/// to whichever tab it belonged to. The guide is now opened by hand and stays
/// on the current tab, so a leftover step is discarded instead of followed.
///
/// The router argument stays because callers sit above `MaterialApp.router`
/// and cannot look a [GoRouter] up themselves. It is unused: resuming no
/// longer navigates.
Future<void> attemptTourResume(BuildContext context, GoRouter _) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final prefs = container.read(appPreferencesProvider);
  if (prefs.tourResumeStep != null) {
    await prefs.setTourResumeStep(null);
  }
}
