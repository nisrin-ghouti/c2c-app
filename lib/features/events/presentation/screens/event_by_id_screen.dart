import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/events_providers.dart';
import 'event_detail_screen.dart';

/// Resolves a shared event link (`AppConfig.eventShareUrl`) to the real
/// [EventDetailScreen].
///
/// Every in-app route into an event detail already holds the `CampusEvent` and
/// pushes `EventDetailScreen` directly; this exists only for the one entry
/// point that has nothing but an id. It fetches through `eventByIdProvider`,
/// the same RLS-gated read every other screen uses, so an event the viewer
/// isn't entitled to simply comes back null and renders the not-found state —
/// a forwarded link can't reveal a private event, and nothing about it needs a
/// separate permission check here.
class EventByIdScreen extends ConsumerWidget {
  const EventByIdScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final eventAsync = ref.watch(eventByIdProvider(eventId));

    return eventAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      // A failed fetch is indistinguishable from "not for you" as far as the
      // viewer is concerned, and saying which would leak whether the event
      // exists. Both render the same message.
      error: (_, _) => _NotFound(l10n: l10n),
      data: (event) {
        if (event == null) return _NotFound(l10n: l10n);
        return EventDetailScreen(event: event);
      },
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        title: Text(l10n.eventNotFoundTitle),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.event_busy_outlined,
                size: 44,
                color: AppColors.mutedForeground,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.eventNotFoundMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.mutedForeground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
