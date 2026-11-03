import '../entities/app_notification.dart';
import '../repositories/notifications_repository.dart';

/// Only the event-reminder rows, for the once-a-day reminder popup.
class ListMyEventReminders {
  const ListMyEventReminders(this._repository);
  final NotificationsRepository _repository;

  Future<List<AppNotification>> call() => _repository.listMyEventReminders();
}

class ListMyNotifications {
  const ListMyNotifications(this._repository);
  final NotificationsRepository _repository;

  Future<List<AppNotification>> call() => _repository.listMyNotifications();
}

class GetUnreadNotificationsCount {
  const GetUnreadNotificationsCount(this._repository);
  final NotificationsRepository _repository;

  Future<int> call() => _repository.getUnreadCount();
}

class MarkAllNotificationsRead {
  const MarkAllNotificationsRead(this._repository);
  final NotificationsRepository _repository;

  Future<void> call() => _repository.markAllAsRead();
}

class MarkNotificationsRead {
  const MarkNotificationsRead(this._repository);
  final NotificationsRepository _repository;

  Future<void> call(List<String> ids) => _repository.markAsRead(ids);
}

class MarkNotificationsUnread {
  const MarkNotificationsUnread(this._repository);
  final NotificationsRepository _repository;

  Future<void> call(List<String> ids) => _repository.markAsUnread(ids);
}

class DeleteNotifications {
  const DeleteNotifications(this._repository);
  final NotificationsRepository _repository;

  Future<void> call(List<String> ids) => _repository.deleteNotifications(ids);
}

class ClearAllNotifications {
  const ClearAllNotifications(this._repository);
  final NotificationsRepository _repository;

  Future<void> call() => _repository.deleteAllNotifications();
}
