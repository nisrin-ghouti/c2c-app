import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../benefits/presentation/screens/benefit_notification_opener.dart';
import '../../../chat/presentation/screens/chat_thread_screen.dart';
import '../../../events/presentation/screens/event_notification_opener.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../../onboarding/domain/entities/demo_key.dart';
import '../../../onboarding/presentation/controllers/demo_flags_controller.dart';
import '../../../onboarding/presentation/widgets/contextual_showcase.dart';
import '../../../surveys/presentation/screens/survey_take_screen.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notifications_providers.dart';
import '../widgets/notification_tile.dart';

/// Where tapping a notification should take the user, based on its [type]
/// and [data] payload. Each type carries the specific id of the thing it's
/// about (event/benefit/survey/chat), so tapping opens that exact item —
/// event and benefit notifications only carry an id, so their openers
/// resolve the id to the full object before handing off to the real detail
/// screen (see `EventNotificationOpener`/`BenefitNotificationOpener`).
void _openNotificationTarget(
  BuildContext context,
  AppNotification notification,
) {
  switch (notification.type) {
    case AppNotificationType.newMessage:
    case AppNotificationType.meetingProposal:
      final chatId = notification.data['chat_id'] as String?;
      final senderId = notification.data['sender_id'] as String?;
      if (chatId == null || senderId == null) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatThreadScreen(
            chatId: chatId,
            otherUserId: senderId,
            otherFullName: (notification.data['sender_name'] as String?) ?? '',
            // Not carried on the notification payload — matches the fallback
            // used everywhere else a hue is missing (avatar_hue ?? 220).
            otherAvatarHue: 220,
          ),
        ),
      );
    case AppNotificationType.eventPublished:
    case AppNotificationType.eventDecision:
    case AppNotificationType.eventReminderTomorrow:
    case AppNotificationType.eventReminderToday:
      final eventId = notification.data['event_id'] as String?;
      if (eventId == null) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EventNotificationOpener(eventId: eventId),
        ),
      );
    case AppNotificationType.benefitPublished:
    case AppNotificationType.benefitRedeemed:
      final benefitId = notification.data['benefit_id'] as String?;
      if (benefitId == null) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BenefitNotificationOpener(benefitId: benefitId),
        ),
      );
    case AppNotificationType.surveyPublished:
      final surveyId = notification.data['survey_id'] as String?;
      if (surveyId == null) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SurveyTakeScreen(surveyId: surveyId)),
      );
    case AppNotificationType.pointsEarned:
    case AppNotificationType.eventPendingApproval:
    case AppNotificationType.reportSubmitted:
    case AppNotificationType.groupMeetingPending:
    case AppNotificationType.unknown:
      // No mobile screen to deep-link into for these (admin-only, or no
      // specific destination) — tapping just leaves the notification read.
      break;
  }
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final Set<String> _selectedIds = {};
  final _firstTileShowcaseKey = GlobalKey();

  bool get _selectionMode => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // Opening the list is "seen" — mark everything read, same convention
    // as the champions-announcement popups marking themselves seen on OK.
    Future.microtask(() async {
      await ref.read(markAllNotificationsReadProvider)();
      ref.invalidate(homeDashboardProvider);
      ref.invalidate(unreadNotificationsCountProvider);
    });
  }

  void _toggleSelected(String id) {
    setState(() {
      if (!_selectedIds.remove(id)) _selectedIds.add(id);
    });
  }

  void _clearSelection() => setState(_selectedIds.clear);

  void _selectAll(List<AppNotification> notifications) {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(notifications.map((n) => n.id));
    });
  }

  Future<void> _markSelected({required bool read}) async {
    final ids = _selectedIds.toList();
    if (read) {
      await ref.read(markNotificationsReadProvider)(ids);
    } else {
      await ref.read(markNotificationsUnreadProvider)(ids);
    }
    if (!mounted) return;
    _clearSelection();
    ref.invalidate(myNotificationsProvider);
    ref.invalidate(unreadNotificationsCountProvider);
    ref.invalidate(homeDashboardProvider);
  }

  Future<void> _deleteSelected(AppLocalizations l10n) async {
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.notificationsDeleteConfirmTitle),
        content: Text(l10n.notificationsDeleteConfirmMessage(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.notificationsDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(deleteNotificationsProvider)(_selectedIds.toList());
    if (!mounted) return;
    _clearSelection();
    ref.invalidate(myNotificationsProvider);
    ref.invalidate(unreadNotificationsCountProvider);
    ref.invalidate(homeDashboardProvider);
  }

  Future<void> _clearAll(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.notificationsClearAllConfirmTitle),
        content: Text(l10n.notificationsClearAllConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.notificationsClearAll),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(clearAllNotificationsProvider)();
    if (!mounted) return;
    _clearSelection();
    ref.invalidate(myNotificationsProvider);
    ref.invalidate(unreadNotificationsCountProvider);
    ref.invalidate(homeDashboardProvider);
  }

  PreferredSizeWidget _appBar(
    AppLocalizations l10n,
    List<AppNotification>? notifications,
  ) {
    if (_selectionMode) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _clearSelection,
        ),
        title: Text(l10n.notificationsSelectedCount(_selectedIds.length)),
        actions: [
          IconButton(
            icon: const Icon(Icons.select_all),
            tooltip: l10n.notificationsSelectAll,
            onPressed: notifications == null
                ? null
                : () => _selectAll(notifications),
          ),
          IconButton(
            icon: const Icon(Icons.mark_email_read_outlined),
            tooltip: l10n.notificationsMarkRead,
            onPressed: () => _markSelected(read: true),
          ),
          IconButton(
            icon: const Icon(Icons.mark_email_unread_outlined),
            tooltip: l10n.notificationsMarkUnread,
            onPressed: () => _markSelected(read: false),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.notificationsDeleteAction,
            onPressed: () => _deleteSelected(l10n),
          ),
        ],
      );
    }
    return AppBar(
      title: Text(l10n.notificationsTitle),
      actions: [
        if (notifications != null && notifications.isNotEmpty)
          PopupMenuButton<void>(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () => _clearAll(l10n),
                child: Text(l10n.notificationsClearAll),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notificationsAsync = ref.watch(myNotificationsProvider);

    return Scaffold(
      appBar: _appBar(l10n, notificationsAsync.valueOrNull),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(myNotificationsProvider.future),
          child: notificationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => ListView(
              children: [
                const SizedBox(height: 80),
                Center(child: Text(l10n.notificationsLoadError)),
              ],
            ),
            data: (notifications) {
              if (notifications.isEmpty) {
                return ListView(
                  children: [
                    const SizedBox(height: 80),
                    Center(
                      child: Text(
                        l10n.notificationsEmpty,
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ),
                  ],
                );
              }
              final showNotificationsDemo =
                  !_selectionMode &&
                  !ref.watch(hasSeenDemoProvider(DemoKey.notifications));
              if (showNotificationsDemo) {
                startContextualDemoOnce(
                  context: context,
                  ref: ref,
                  key: DemoKey.notifications,
                  showcaseKeys: [_firstTileShowcaseKey],
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return NotificationTile(
                    notification: notification,
                    selectionMode: _selectionMode,
                    selected: _selectedIds.contains(notification.id),
                    onTap: () => _selectionMode
                        ? _toggleSelected(notification.id)
                        : _openNotificationTarget(context, notification),
                    onLongPress: () => _toggleSelected(notification.id),
                    // Wrapped for the first row regardless of the "seen"
                    // flag: markSeen fires right after the showcase starts,
                    // and dropping the wrapper would unmount the target
                    // mid-demo. Only starting the demo consults the flag.
                    rowWrapper: index == 0
                        ? (child) => ContextualShowcase(
                            showcaseKey: _firstTileShowcaseKey,
                            title: l10n.coachMarkNotificationsTitle,
                            description: l10n.coachMarkNotificationsDescription,
                            child: child,
                          )
                        : null,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
