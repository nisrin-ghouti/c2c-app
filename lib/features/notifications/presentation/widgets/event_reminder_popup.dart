import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/storage/shared_preferences_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/usecases/localized_notification_field.dart';
import '../../domain/usecases/pending_event_reminders.dart';
import '../providers/notifications_providers.dart';

/// Shows the centre-screen reminder dialog once per user, per event, per
/// reminder day.
///
/// Mounted by `AppShell` as a zero-size sibling, so "the first time the user
/// opens the app on the relevant day" means the first time the signed-in shell
/// builds that day — whichever tab they land on. It renders nothing; the
/// dialog is pushed onto the navigator and this widget only owns the decision
/// to push it. Deliberately NOT a wrapper around the shell's body: see the
/// note in [build].
///
/// Where the once-only guarantee comes from:
///   * the list of candidates is `pendingEventReminders`, which drops anything
///     whose reminder day isn't today and anything this device has already
///     shown (`AppPreferences.hasShownReminderPopup`);
///   * the flag is written BEFORE the dialog is awaited, so dismissing it (or
///     killing the app while it is up) can't leave it un-marked and due again;
///   * `_shownThisSession` stops a rebuild from pushing a second copy of a
///     dialog that is already on screen, which the persisted flag alone
///     wouldn't catch inside one frame.
///
/// The notification row is untouched either way — unread or read, it stays in
/// the notification centre, which is where a reminder whose popup was never
/// shown (app not opened that day) remains available.
class EventReminderPopupHost extends ConsumerStatefulWidget {
  const EventReminderPopupHost({super.key});

  @override
  ConsumerState<EventReminderPopupHost> createState() =>
      _EventReminderPopupHostState();
}

class _EventReminderPopupHostState
    extends ConsumerState<EventReminderPopupHost>
    with WidgetsBindingObserver {
  /// Keys (`eventId.kind.day`) already pushed in this app run.
  final _shownThisSession = <String>{};
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // An app that is only ever backgrounded never rebuilds this on its own, so
    // a reminder that arrived overnight — or a day that simply rolled over —
    // would not be considered until the process was killed. Refetching on
    // resume is what makes "the first time the user opens the app that day"
    // true for a backgrounded app as well as a cold start.
    ref.invalidate(myEventRemindersProvider);
  }

  Future<void> _maybeShow() async {
    if (_showing) return;

    final userId = ref.read(currentAuthSessionProvider).userId;
    if (userId == null) return;

    final notifications = ref.read(myEventRemindersProvider).valueOrNull;
    if (notifications == null) return;

    final prefs = ref.read(appPreferencesProvider);
    final due = pendingEventReminders(
      notifications,
      today: DateTime.now(),
      hasBeenShown: (reminder) {
        final key = '${reminder.eventId}.${reminder.kind}.${reminder.eventDay}';
        if (_shownThisSession.contains(key)) return true;
        return prefs.hasShownReminderPopup(
          userId: userId,
          eventId: reminder.eventId,
          kind: reminder.kind,
          eventDay: reminder.eventDay,
        );
      },
    );
    if (due.isEmpty) return;

    _showing = true;
    // One dialog per build pass even when several are due — the rest stay due
    // and the next pass (or the user reopening the app) picks them up. Showing
    // three stacked dialogs at launch would be worse than showing them in
    // sequence.
    final reminder = due.first;
    final key = '${reminder.eventId}.${reminder.kind}.${reminder.eventDay}';
    _shownThisSession.add(key);
    await prefs.setShownReminderPopup(
      userId: userId,
      eventId: reminder.eventId,
      kind: reminder.kind,
      eventDay: reminder.eventDay,
    );

    if (!mounted) {
      _showing = false;
      return;
    }
    final openEvent = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _EventReminderDialog(reminder: reminder),
    );
    _showing = false;
    if (openEvent == true && mounted) {
      context.push(AppRoutes.eventById(reminder.eventId));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Its own narrow query (reminder rows only), so pinning it here for the
    // life of the shell doesn't make the notification centre's list stale.
    // No polling: it is fetched once per launch and once per resume.
    ref.watch(myEventRemindersProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeShow();
    });
    // Renders NOTHING and wraps nothing.
    //
    // This used to wrap the shell's whole body. That put an async `ref.watch`
    // above `navigationShell`, so the moment the reminder query resolved —
    // about a second after launch — the entire shell subtree rebuilt,
    // including every `TourShowcase` target on Home. That is exactly when the
    // first-run tour is starting, and remounting a showcase's target while it
    // is running tears the sequence down. As a zero-size sibling in the
    // Stack, its rebuilds stay local to itself.
    return const SizedBox.shrink();
  }
}

class _EventReminderDialog extends StatelessWidget {
  const _EventReminderDialog({required this.reminder});

  final EventReminder reminder;

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// toLocal(): the payload timestamps are UTC, and printing their raw fields
  /// would show UTC wall-clock time to a student reading campus time.
  static String _time(DateTime utc) {
    final dt = utc.toLocal();
    return '${_two(dt.hour)}:${_two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final title = localizedNotificationField(
      reminder.data,
      'title',
      languageCode: languageCode,
    );
    final location = localizedNotificationField(
      reminder.data,
      'location',
      languageCode: languageCode,
    );

    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          const Icon(Icons.alarm, size: 20, color: AppColors.primaryStrong),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              reminder.isToday
                  ? l10n.eventReminderPopupTitleToday
                  : l10n.eventReminderPopupTitleTomorrow,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          const SizedBox(height: 12),
          if (location.isNotEmpty)
            _Row(label: l10n.eventReminderPopupLocationLabel, value: location),
          _Row(
            label: l10n.eventReminderPopupStartLabel,
            value: _time(reminder.startsAt),
          ),
          _Row(
            label: l10n.eventReminderPopupEndLabel,
            value: _time(reminder.endsAt),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.eventReminderPopupDismiss),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.eventReminderPopupOpenEvent),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mutedForeground,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
