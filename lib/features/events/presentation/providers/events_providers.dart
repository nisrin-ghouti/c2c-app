import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgresChangeEvent, SupabaseClient;

import '../../../../main.dart' show supabase;
import '../../data/datasources/events_remote_data_source.dart';
import '../../data/repositories/events_repository_impl.dart';
import '../../domain/entities/campus_event.dart';
import '../../domain/entities/event_session.dart';
import '../../domain/repositories/events_repository.dart';
import '../../domain/usecases/event_management_usecases.dart';
import '../../domain/usecases/filter_events_in_next_thirty_days.dart';
import '../../domain/usecases/load_event_list.dart';
import '../../domain/usecases/load_my_events.dart';

final _supabaseClientProvider = Provider<SupabaseClient>((ref) => supabase);

final _eventsRemoteDataSourceProvider = Provider<EventsRemoteDataSource>((ref) {
  return EventsRemoteDataSource(ref.watch(_supabaseClientProvider));
});

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return EventsRepositoryImpl(ref.watch(_eventsRemoteDataSourceProvider));
});

final loadEventListProvider = Provider(
  (ref) => LoadEventList(ref.watch(eventsRepositoryProvider)),
);
final uploadEventImageProvider = Provider(
  (ref) => UploadEventImage(ref.watch(eventsRepositoryProvider)),
);

final confirmAttendanceByStudentIdProvider = Provider(
  (ref) => ConfirmAttendanceByStudentId(ref.watch(eventsRepositoryProvider)),
);
final lookupStudentNameByIdProvider = Provider(
  (ref) => LookupStudentNameById(ref.watch(eventsRepositoryProvider)),
);

final loadMyEventsProvider = Provider(
  (ref) => LoadMyEvents(ref.watch(eventsRepositoryProvider)),
);
final registerForEventProvider = Provider(
  (ref) => RegisterForEvent(ref.watch(eventsRepositoryProvider)),
);
final cancelEventRegistrationProvider = Provider(
  (ref) => CancelEventRegistration(ref.watch(eventsRepositoryProvider)),
);
final deleteEventProvider = Provider(
  (ref) => DeleteEvent(ref.watch(eventsRepositoryProvider)),
);
final getEventRegistrantsProvider = Provider(
  (ref) => GetEventRegistrants(ref.watch(eventsRepositoryProvider)),
);
final createEventProvider = Provider(
  (ref) => CreateEvent(ref.watch(eventsRepositoryProvider)),
);
final updateEventProvider = Provider(
  (ref) => UpdateEvent(ref.watch(eventsRepositoryProvider)),
);
final getPendingEventsProvider = Provider(
  (ref) => GetPendingEvents(ref.watch(eventsRepositoryProvider)),
);
final approveEventProvider = Provider(
  (ref) => ApproveEvent(ref.watch(eventsRepositoryProvider)),
);
final rejectEventProvider = Provider(
  (ref) => RejectEvent(ref.watch(eventsRepositoryProvider)),
);
final getEventSessionsProvider = Provider(
  (ref) => GetEventSessions(ref.watch(eventsRepositoryProvider)),
);

/// Raw repository passthroughs (no usecase wrapper needed — these are
/// simple single-call actions, same as `RolesRepository`'s methods).
final startEventQrProvider = Provider((ref) {
  return ref.watch(eventsRepositoryProvider).startEventQr;
});
final setEventQrEnabledProvider = Provider((ref) {
  return ref.watch(eventsRepositoryProvider).setEventQrEnabled;
});
final scanEventAttendanceProvider = Provider((ref) {
  return ref.watch(eventsRepositoryProvider).scanEventAttendance;
});
final getEventStatsProvider = Provider((ref) {
  return ref.watch(eventsRepositoryProvider).getEventStats;
});

/// Drops the cached event lists whenever an event (or one of a Program's
/// sessions) changes in the database, so an edit made in the admin panel
/// shows up in the app without the student doing anything.
///
/// Why this is needed at all: every event provider here is `autoDispose`,
/// but the Home screen watches `eventListProvider` for as long as the app
/// is running, so nothing ever disposes and the session's first fetch was
/// its only fetch. Short of pull-to-refresh, the cache outlived everything
/// but killing the process — which is precisely the symptom that was
/// reported.
///
/// Mounted once by `AppShell`, so it lives exactly as long as the signed-in
/// session and is torn down with it.
///
/// Requires `events` and `event_sessions` to be in the `supabase_realtime`
/// publication (migration 0063). Without it this subscribes, reports
/// healthy, and never fires — the same silent failure 0005 documents.
/// Bumped once per realtime event-change burst by [eventsLiveRefreshProvider].
///
/// Exists so screens outside this feature can follow event changes without
/// this file having to reach into theirs. `homeDashboardProvider` watches it:
/// Home's stat cards are computed in one RPC payload that this feature knows
/// nothing about, and invalidating it from here directly would mean the events
/// feature importing the home feature.
final eventsChangedCounterProvider = StateProvider<int>((ref) => 0);

final eventsLiveRefreshProvider = Provider<void>((ref) {
  final channel = supabase.channel('public:events');

  // An admin save arrives as a burst: the event row, then its sessions,
  // then a second write a moment later when the translate function fills
  // the other languages. Coalescing means one refetch per burst instead of
  // one per row touched.
  Timer? debounce;

  void invalidateEventCaches() {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 400), () {
      ref.invalidate(eventListProvider);
      ref.invalidate(myEventsProvider);
      // Capacity is read off the event row, so an organizer changing it has
      // to re-open the registration UI too.
      ref.invalidate(eventRegistrationCountsProvider);
      ref.invalidate(eventRegistrationCountProvider);
      // Families: invalidating the provider itself clears every argument.
      ref.invalidate(eventByIdProvider);
      ref.invalidate(eventSessionsProvider);
      ref.invalidate(myAcceptedProgramIdsProvider);
      // Anything outside this feature that renders event data — Home's
      // summary counts — follows this instead of being invalidated by name.
      ref.read(eventsChangedCounterProvider.notifier).state++;
    });
  }

  for (final table in const ['events', 'event_sessions']) {
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: table,
      callback: (_) => invalidateEventCaches(),
    );
  }

  channel.subscribe();

  ref.onDispose(() {
    debounce?.cancel();
    supabase.removeChannel(channel);
  });
});

/// The browsable upcoming-events list (Home's "Upcoming Events" stat-card
/// and the Events tab both read this).
final eventListProvider = FutureProvider.autoDispose<List<CampusEvent>>((ref) {
  return ref.watch(loadEventListProvider)();
});

/// Just the events happening within the next 30 days — Home's "Events in the
/// Next Month" section.
///
/// Derived from [eventListProvider] so the two Home sections share one fetch
/// and one realtime invalidation, but the window test is this section's own
/// (see `filterEventsInNextThirtyDays`): it re-checks every event's dates
/// itself rather than trusting whatever ordering or horizon the upcoming list
/// happens to have, so changing one section can't quietly change the other.
final eventsNextThirtyDaysProvider =
    FutureProvider.autoDispose<List<CampusEvent>>((ref) async {
      final events = await ref.watch(eventListProvider.future);
      return filterEventsInNextThirtyDays(events);
    });

/// Every event the viewer has registered for or attended, past or future —
/// backs the "My Events" screen.
final myEventsProvider = FutureProvider.autoDispose<List<CampusEvent>>((ref) {
  return ref.watch(loadMyEventsProvider)();
});

/// A single event by id — e.g. so a notification can deep-link straight to
/// the event it's about instead of the generic events list.
final eventByIdProvider = FutureProvider.autoDispose
    .family<CampusEvent?, String>((ref, eventId) {
      return ref.watch(eventsRepositoryProvider).getEventById(eventId);
    });

/// event_id → live registration count, for every event in the browsable list.
///
/// One RPC for the whole list rather than one per card. Invalidated with the
/// event caches by [eventsLiveRefreshProvider], so an organizer raising the
/// capacity frees the Register button up without the student doing anything;
/// another student's cancellation is picked up on the next load or
/// pull-to-refresh, since RLS means realtime never delivers someone else's
/// registration row.
final eventRegistrationCountsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
      final events = await ref.watch(eventListProvider.future);
      return ref
          .watch(eventsRepositoryProvider)
          .getRegistrationCountsByEvent(events.map((e) => e.id).toList());
    });

/// The live registration count for one event — what the detail screen pairs
/// with `CampusEvent.capacity` to decide whether registration is open.
///
/// Keyed by id rather than by `CampusEvent` so the family key is a value:
/// `CampusEvent` has no `==`, which would hand every rebuild a fresh instance
/// and therefore a fresh provider.
final eventRegistrationCountProvider = FutureProvider.autoDispose
    .family<int, String>((ref, eventId) async {
      final counts = await ref
          .watch(eventsRepositoryProvider)
          .getRegistrationCountsByEvent([eventId]);
      return counts[eventId] ?? 0;
    });

/// The programs the viewer has been accepted onto.
///
/// Drives the "waiting for approval" state: a student who holds a
/// registration for a program but is absent from this set has applied and not
/// yet been taken on. Read from the backend rather than inferred from the tap
/// that registered them, so the status survives a restart and reflects what an
/// admin has actually done.
///
/// Invalidated with the event caches by [eventsLiveRefreshProvider] — plus by
/// its own realtime subscription below, since being accepted is a write to a
/// different table that no event-row change accompanies.
final myAcceptedProgramIdsProvider = FutureProvider.autoDispose<Set<String>>((
  ref,
) {
  return ref.watch(eventsRepositoryProvider).getMyAcceptedProgramIds();
});

/// Drops the accepted-programs cache when the viewer's own acceptance row
/// appears or disappears, so being approved updates the screen the student is
/// looking at instead of waiting for a restart.
///
/// Mounted by `AppShell` alongside the other live-refresh providers. RLS
/// limits the subscription to the viewer's own rows, so this carries nothing
/// about anyone else.
///
/// Requires `program_accepted_participants` in the `supabase_realtime`
/// publication (migration 0087).
final programAcceptanceLiveRefreshProvider = Provider<void>((ref) {
  final channel = supabase.channel('public:program_accepted_participants');

  Timer? debounce;
  void invalidate() {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 400), () {
      ref.invalidate(myAcceptedProgramIdsProvider);
    });
  }

  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'program_accepted_participants',
    callback: (_) => invalidate(),
  );
  channel.subscribe();

  ref.onDispose(() {
    debounce?.cancel();
    supabase.removeChannel(channel);
  });
});

/// Bulk co-host grants for the current user — fetched once per list screen
/// rather than one `hasEventAccessProvider` watch per card.
final myHostAccessEventIdsProvider = FutureProvider.autoDispose<Set<String>>((
  ref,
) {
  return ref.watch(eventsRepositoryProvider).getMyHostAccessEventIds();
});

/// A Program's sessions, chronological, with the viewer's status stitched
/// on — backs `program_detail_screen`.
final eventSessionsProvider = FutureProvider.autoDispose
    .family<List<EventSession>, String>((ref, eventId) {
      return ref.watch(getEventSessionsProvider)(eventId);
    });
