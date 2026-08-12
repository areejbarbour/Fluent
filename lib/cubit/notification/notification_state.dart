import 'package:fluent/data/models/notification_model.dart';

class NotificationState {
  final bool loading;
  final bool actionLoading;
  final String? error;
  final String? message;
  final bool actionSuccess;

  final List<AppNotificationModel> notifications;
  final int unreadCount;

  const NotificationState({
    this.loading = false,
    this.actionLoading = false,
    this.error,
    this.message,
    this.actionSuccess = false,
    this.notifications = const [],
    this.unreadCount = 0,
  });

  /// Unread items only (client-side filter).
  List<AppNotificationModel> get unreadNotifications =>
      notifications.where((n) => !n.isRead).toList();

  NotificationState copyWith({
    bool? loading,
    bool? actionLoading,
    String? error,
    String? message,
    bool? actionSuccess,
    List<AppNotificationModel>? notifications,
    int? unreadCount,
  }) {
    return NotificationState(
      loading: loading ?? this.loading,
      actionLoading: actionLoading ?? this.actionLoading,
      error: error,
      message: message,
      actionSuccess: actionSuccess ?? this.actionSuccess,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
