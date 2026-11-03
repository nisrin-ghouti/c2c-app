import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../events/presentation/providers/events_providers.dart';
import '../../domain/entities/home_dashboard.dart';
import '../providers/home_providers.dart';

/// The full dashboard payload — one loading/error/data state for the whole
/// home screen.
///
/// Re-runs when an event changes in the database. The payload carries the
/// "Upcoming Events" count, which is computed server-side and so isn't covered
/// by `eventListProvider`'s own invalidation — without this, an event added or
/// removed from the admin panel left a stale number on Home until the app was
/// restarted, which is the same staleness `eventsLiveRefreshProvider` fixes
/// for the lists.
final homeDashboardProvider = FutureProvider.autoDispose<HomeDashboard>((ref) {
  final viewerId = ref.watch(currentAuthSessionProvider).userId!;
  ref.watch(eventsChangedCounterProvider);
  return ref.watch(loadHomeDashboardProvider)(viewerId);
});
