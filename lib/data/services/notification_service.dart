import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

/// Notifications APIs — matches backend NotificationController + FirebaseTokenController.
/// Available for both Teacher and Student (auth:sanctum).
class NotificationService {
  final Dio dio;
  NotificationService(this.dio);

  Options get _opts => Options(
    headers: {'Accept': 'application/json'},
    validateStatus: (status) => status != null && status < 500,
  );

  /// POST /api/firebase/token
  /// Body matches RegisterFirebaseTokenRequest:
  ///   token (required), device_type in: web|mobile|tablet, device_name optional
  Future<Response> registerFirebaseToken({
    required String token,
    String? deviceType,
    String? deviceName,
  }) async {
    return await dio.post(
      apiFirebaseToken,
      data: {
        'token': token,
        if (deviceType != null) 'device_type': deviceType,
        if (deviceName != null) 'device_name': deviceName,
      },
      options: _opts,
    );
  }

  /// GET /api/notifications
  /// Response: list of NotificationResource (ordered: unread first, then newest)
  Future<Response> getNotifications() async {
    return await dio.get(apiNotifications, options: _opts);
  }

  /// GET /api/notifications/unread
  /// Note: backend currently misses getUnreadNotifications() in service —
  /// this call may return 500 until backend is fixed. Prefer filtering client-side
  /// from getNotifications() if needed.
  Future<Response> getUnreadNotifications() async {
    return await dio.get(apiNotificationsUnread, options: _opts);
  }

  /// GET /api/notifications/unreadcount
  /// Response: { "number of unread notification": int }
  Future<Response> getUnreadCount() async {
    return await dio.get(apiNotificationsUnreadCount, options: _opts);
  }

  /// PATCH /api/notifications/{notification}/markAsRead
  Future<Response> markAsRead(String notificationId) async {
    return await dio.patch(
      apiNotificationMarkAsRead(notificationId),
      options: _opts,
    );
  }

  /// PATCH /api/notifications/markAllAsRead
  Future<Response> markAllAsRead() async {
    return await dio.patch(apiNotificationsMarkAllAsRead, options: _opts);
  }

  /// DELETE /api/notifications/{notification}/delete
  Future<Response> deleteNotification(String notificationId) async {
    return await dio.delete(
      apiNotificationDelete(notificationId),
      options: _opts,
    );
  }
}
