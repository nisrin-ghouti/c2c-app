import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../providers/events_providers.dart';
import 'event_detail_screen.dart';

/// Resolves a bare event id (e.g. from a notification's `data` payload,
/// which only ever carries the id) into the full [CampusEvent] the real
/// detail screen needs, then hands off to it — so tapping an event
/// notification lands on that specific event instead of the generic list.
class EventNotificationOpener extends ConsumerWidget {
  const EventNotificationOpener({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final eventAsync = ref.watch(eventByIdProvider(eventId));

    return eventAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.notificationTargetLoadError)),
      ),
      data: (event) => event == null
          ? Scaffold(
              appBar: AppBar(),
              body: Center(child: Text(l10n.notificationTargetLoadError)),
            )
          : EventDetailScreen(event: event),
    );
  }
}
