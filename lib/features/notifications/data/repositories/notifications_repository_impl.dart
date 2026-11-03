import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_data_source.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._remote);

  final NotificationsRemoteDataSource _remote;

  @override
  Future<List<AppNotification>> listMyNotifications() async {
    return _map(await _remote.listMyNotifications());
  }

  @override
  Future<List<AppNotification>> listMyEventReminders() async {
    return _map(await _remote.listMyEventReminders());
  }

  List<AppNotification> _map(List<Map<String, dynamic>> rows) {
    return rows.map((row) {
      return AppNotification(
        id: row['id'] as String,
        type: switch (row['type']) {
          'points_earned' => AppNotificationType.pointsEarned,
          'new_message' => AppNotificationType.newMessage,
          'meeting_proposal' => AppNotificationType.meetingProposal,
          'event_pending_approval' => AppNotificationType.eventPendingApproval,
          'event_published' => AppNotificationType.eventPublished,
          'benefit_published' => AppNotificationType.benefitPublished,
          'report_submitted' => AppNotificationType.reportSubmitted,
          'event_decision' => AppNotificationType.eventDecision,
          'group_meeting_pending' => AppNotificationType.groupMeetingPending,
          'benefit_redeemed' => AppNotificationType.benefitRedeemed,
          'survey_published' => AppNotificationType.surveyPublished,
          'event_reminder_tomorrow' =>
            AppNotificationType.eventReminderTomorrow,
          'event_reminder_today' => AppNotificationType.eventReminderToday,
          _ => AppNotificationType.unknown,
        },
        data: Map<String, dynamic>.from(row['data'] as Map? ?? const {}),
        createdAt: DateTime.parse(row['created_at'] as String),
        readAt: row['read_at'] != null
            ? DateTime.parse(row['read_at'] as String)
            : null,
      );
    }).toList();
  }

  @override
  Future<int> getUnreadCount() => _remote.getUnreadCount();

  @override
  Future<void> markAllAsRead() => _remote.markAllAsRead();

  @override
  Future<void> markAsRead(List<String> ids) => _remote.markAsRead(ids);

  @override
  Future<void> markAsUnread(List<String> ids) => _remote.markAsUnread(ids);

  @override
  Future<void> deleteNotifications(List<String> ids) =>
      _remote.deleteNotifications(ids);

  @override
  Future<void> deleteAllNotifications() => _remote.deleteAllNotifications();
}
