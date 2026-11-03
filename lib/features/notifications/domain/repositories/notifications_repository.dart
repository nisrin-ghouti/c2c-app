import '../entities/app_notification.dart';

abstract interface class NotificationsRepository {
  Future<List<AppNotification>> listMyNotifications();

  /// Only the event-reminder rows — what the once-a-day reminder popup reads.
  Future<List<AppNotification>> listMyEventReminders();
  Future<int> getUnreadCount();
  Future<void> markAllAsRead();
  Future<void> markAsRead(List<String> ids);
  Future<void> markAsUnread(List<String> ids);
  Future<void> deleteNotifications(List<String> ids);
  Future<void> deleteAllNotifications();
}
