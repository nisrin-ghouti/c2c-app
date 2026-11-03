import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/localized_notification_field.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onLongPress,
    this.selectionMode = false,
    this.selected = false,
    this.rowWrapper,
  });

  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Whether the list is currently in multi-select mode — swaps the leading
  /// type icon for a checkbox and tints the tile when [selected].
  final bool selectionMode;
  final bool selected;

  /// Optionally wraps the whole tile — lets the list screen spotlight the
  /// first row for the first-time "long-press to select" hint.
  final Widget Function(Widget child)? rowWrapper;

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  // toLocal(): timestamps arrive as UTC; format them in campus time.
  String _timestamp(DateTime utc) {
    final dt = utc.toLocal();
    return '${_twoDigits(dt.hour)}:${_twoDigits(dt.minute)}, '
        '${_twoDigits(dt.day)}.${_twoDigits(dt.month)}.${dt.year}';
  }

  IconData get _icon => switch (notification.type) {
    AppNotificationType.pointsEarned => Icons.push_pin_outlined,
    AppNotificationType.newMessage => Icons.chat_bubble_outline,
    AppNotificationType.meetingProposal => Icons.event_outlined,
    AppNotificationType.eventPendingApproval => Icons.approval_outlined,
    AppNotificationType.eventPublished => Icons.celebration_outlined,
    AppNotificationType.benefitPublished => Icons.card_giftcard_outlined,
    AppNotificationType.reportSubmitted => Icons.flag_outlined,
    AppNotificationType.eventDecision => Icons.fact_check_outlined,
    AppNotificationType.groupMeetingPending => Icons.groups_outlined,
    AppNotificationType.benefitRedeemed => Icons.celebration_outlined,
    AppNotificationType.surveyPublished => Icons.assignment_outlined,
    AppNotificationType.eventReminderTomorrow ||
    AppNotificationType.eventReminderToday => Icons.alarm_outlined,
    AppNotificationType.unknown => Icons.notifications_outlined,
  };

  /// [languageCode] is needed because several payloads now carry per-locale
  /// copies of their title (see `localizedNotificationField`): the row's text
  /// has to follow the app's language, not the language the organizer typed
  /// it in.
  String _body(AppLocalizations l10n, String languageCode) {
    String localized(String field) => localizedNotificationField(
      notification.data,
      field,
      languageCode: languageCode,
    );

    switch (notification.type) {
      case AppNotificationType.pointsEarned:
        final amount = (notification.data['amount'] as num?)?.toInt() ?? 0;
        final metadata = notification.data['metadata'] as Map?;
        final title =
            (metadata?['event_title'] ??
                    metadata?['session_title'] ??
                    metadata?['benefit_id'])
                as String?;
        return title != null && title.isNotEmpty
            ? l10n.notificationPointsEarnedWithTitle(amount, title)
            : l10n.notificationPointsEarned(amount);
      case AppNotificationType.newMessage:
        final senderName = (notification.data['sender_name'] as String?) ?? '';
        return l10n.notificationNewMessage(senderName);
      case AppNotificationType.meetingProposal:
        final scheduledAtRaw = notification.data['scheduled_at'] as String?;
        if (scheduledAtRaw == null) {
          return l10n.notificationMeetingProposalGeneric;
        }
        final parsed = DateTime.tryParse(scheduledAtRaw);
        if (parsed == null) return l10n.notificationMeetingProposalGeneric;
        final scheduledAt = parsed.toLocal();
        final time =
            '${_twoDigits(scheduledAt.hour)}:${_twoDigits(scheduledAt.minute)}, '
            '${_twoDigits(scheduledAt.day)}.${_twoDigits(scheduledAt.month)}';
        return l10n.notificationMeetingProposal(time);
      case AppNotificationType.eventPendingApproval:
        final title = localized('title');
        return title.isEmpty
            ? l10n.notificationEventPendingGeneric
            : l10n.notificationEventPending(title);
      case AppNotificationType.eventPublished:
        final title = localized('title');
        return title.isEmpty
            ? l10n.notificationEventPublishedGeneric
            : l10n.notificationEventPublished(title);
      case AppNotificationType.benefitPublished:
        final title = localized('title');
        return title.isEmpty
            ? l10n.notificationBenefitPublishedGeneric
            : l10n.notificationBenefitPublished(title);
      case AppNotificationType.reportSubmitted:
        return l10n.notificationReportSubmitted;
      case AppNotificationType.eventDecision:
        final title = localized('title');
        final approved = notification.data['status'] == 'approved';
        if (approved) {
          return title.isEmpty
              ? l10n.notificationEventApprovedGeneric
              : l10n.notificationEventApproved(title);
        }
        // A rejection without a stated reason is the common case — don't
        // render a dangling "because:" with nothing after it.
        final reason = (notification.data['reason'] as String?)?.trim() ?? '';
        if (title.isEmpty) return l10n.notificationEventRejectedGeneric;
        return reason.isEmpty
            ? l10n.notificationEventRejected(title)
            : l10n.notificationEventRejectedWithReason(title, reason);
      case AppNotificationType.groupMeetingPending:
        return l10n.notificationGroupMeetingPending;
      case AppNotificationType.benefitRedeemed:
        final title = localized('title');
        return title.isEmpty
            ? l10n.notificationBenefitRedeemedGeneric
            : l10n.notificationBenefitRedeemed(title);
      case AppNotificationType.surveyPublished:
        final title = (notification.data['title'] as String?) ?? '';
        return title.isEmpty
            ? l10n.notificationSurveyPublishedGeneric
            : l10n.notificationSurveyPublished(title);
      case AppNotificationType.eventReminderTomorrow:
        final title = localized('title');
        return title.isEmpty
            ? l10n.notificationEventReminderTomorrowGeneric
            : l10n.notificationEventReminderTomorrow(title);
      case AppNotificationType.eventReminderToday:
        final title = localized('title');
        return title.isEmpty
            ? l10n.notificationEventReminderTodayGeneric
            : l10n.notificationEventReminderToday(title);
      case AppNotificationType.unknown:
        return l10n.notificationGeneric;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;

    return (rowWrapper ?? (child) => child)(_tile(l10n, languageCode));
  }

  Widget _tile(AppLocalizations l10n, String languageCode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? AppColors.primary
              : notification.isUnread
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.border,
          width: selected || notification.isUnread ? 1.4 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectionMode)
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Checkbox(
                      value: selected,
                      onChanged: (_) => onTap?.call(),
                    ),
                  )
                else
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.mint.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_icon, size: 16, color: AppColors.foreground),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _body(l10n, languageCode),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _timestamp(notification.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
