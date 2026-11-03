import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../../../../main.dart' show supabase;
import '../../data/datasources/notifications_remote_data_source.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../domain/usecases/notifications_usecases.dart';

final _supabaseClientProvider = Provider<SupabaseClient>((ref) => supabase);

final _notificationsRemoteDataSourceProvider =
    Provider<NotificationsRemoteDataSource>((ref) {
      return NotificationsRemoteDataSource(ref.watch(_supabaseClientProvider));
    });

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepositoryImpl(
    ref.watch(_notificationsRemoteDataSourceProvider),
  );
});

final listMyNotificationsProvider = Provider(
  (ref) => ListMyNotifications(ref.watch(notificationsRepositoryProvider)),
);
final markAllNotificationsReadProvider = Provider(
  (ref) => MarkAllNotificationsRead(ref.watch(notificationsRepositoryProvider)),
);
final getUnreadNotificationsCountProvider = Provider(
  (ref) =>
      GetUnreadNotificationsCount(ref.watch(notificationsRepositoryProvider)),
);
final markNotificationsReadProvider = Provider(
  (ref) => MarkNotificationsRead(ref.watch(notificationsRepositoryProvider)),
);
final markNotificationsUnreadProvider = Provider(
  (ref) => MarkNotificationsUnread(ref.watch(notificationsRepositoryProvider)),
);
final deleteNotificationsProvider = Provider(
  (ref) => DeleteNotifications(ref.watch(notificationsRepositoryProvider)),
);
final clearAllNotificationsProvider = Provider(
  (ref) => ClearAllNotifications(ref.watch(notificationsRepositoryProvider)),
);

final myNotificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) {
      return ref.watch(listMyNotificationsProvider)();
    });

final listMyEventRemindersProvider = Provider(
  (ref) => ListMyEventReminders(ref.watch(notificationsRepositoryProvider)),
);

/// The viewer's event-reminder rows — read by `EventReminderPopupHost`.
///
/// Deliberately NOT derived from [myNotificationsProvider]. That one is
/// autoDispose and alive only while the notifications screen is open, so each
/// visit refetches; the popup host is mounted by `AppShell` for the whole
/// session, and watching the shared provider from there would pin its cache
/// and leave the notification centre showing a session-old list. Its own
/// narrow query (at most 20 reminder rows) keeps the two independent.
///
/// Refetched on app launch and on each resume — see the lifecycle hook in
/// `EventReminderPopupHost`, which is what "the first time the user opens the
/// app on the relevant day" means for an app that was only backgrounded.
final myEventRemindersProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) {
      return ref.watch(listMyEventRemindersProvider)();
    });

/// Badge count for `AppHeaderBar`'s bell icon — separate from
/// [myNotificationsProvider] so a lightweight COUNT query backs the badge
/// shown on every screen, instead of fetching the full notification list.
final unreadNotificationsCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(getUnreadNotificationsCountProvider)();
});
