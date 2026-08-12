import 'package:dio/dio.dart';
import 'package:fluent/data/models/notification_model.dart';
import 'package:fluent/data/services/notification_service.dart';

class NotificationRepository {
  final NotificationService service;
  NotificationRepository(this.service);

  // ────────────────────────────────────────────
  // Shared helpers (same conventions as ContentReviewRepository)
  // ────────────────────────────────────────────

  String _extractMessage(dynamic data, String fallback) {
    if (data is! Map) return fallback;
    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final firstValue = errors.values.first;
      if (firstValue is List && firstValue.isNotEmpty) {
        return firstValue.first.toString();
      }
      if (firstValue is String) return firstValue;
    }
    if (data['message'] is String && (data['message'] as String).isNotEmpty) {
      return data['message'] as String;
    }
    if (data['error'] is String && (data['error'] as String).isNotEmpty) {
      return data['error'] as String;
    }
    // Backend ownership errors:
    // "You cannot mark this notification as read."
    // "You cannot delete this notification."
    if (data['notification'] is List &&
        (data['notification'] as List).isNotEmpty) {
      return (data['notification'] as List).first.toString();
    }
    if (data['notification'] is String) {
      return data['notification'] as String;
    }
    return fallback;
  }

  Map<String, dynamic> _errorPayload(DioException e) {
    final data = e.response?.data;
    return {
      'success': false,
      'message': _extractMessage(data, e.message ?? 'Request failed'),
      'errors': data is Map ? data['errors'] : null,
    };
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  List<AppNotificationModel> _parseList(dynamic data) {
    final list = <AppNotificationModel>[];

    // Laravel Resource::collection → usually { "data": [ ... ] }
    // Sometimes direct list.
    List? rawList;
    if (data is List) {
      rawList = data;
    } else if (data is Map) {
      final inner = data['data'];
      if (inner is List) rawList = inner;
    }

    if (rawList == null) return list;

    for (final item in rawList) {
      if (item is Map) {
        list.add(
          AppNotificationModel.fromJson(Map<String, dynamic>.from(item)),
        );
      }
    }
    return list;
  }

  // ────────────────────────────────────────────
  // 1) POST /api/firebase/token
  // ────────────────────────────────────────────
  Future<Map<String, dynamic>> registerFirebaseToken({
    required String token,
    String? deviceType,
    String? deviceName,
  }) async {
    try {
      final response = await service.registerFirebaseToken(
        token: token,
        deviceType: deviceType,
        deviceName: deviceName,
      );
      final data = response.data;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Firebase token registered successfully.',
          'raw': data,
        };
      }

      return {
        'success': false,
        'message': _extractMessage(data, 'Failed to register Firebase token'),
        'errors': data is Map ? data['errors'] : null,
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  // ────────────────────────────────────────────
  // 2) GET /api/notifications
  // ────────────────────────────────────────────
  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final response = await service.getNotifications();
      final data = response.data;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final notifications = _parseList(data);
        return {'success': true, 'notifications': notifications};
      }

      return {
        'success': false,
        'message': _extractMessage(data, 'Failed to load notifications'),
        'errors': data is Map ? data['errors'] : null,
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  // ────────────────────────────────────────────
  // 3) GET /api/notifications/unread
  //    Fallback: if backend 500, caller can filter from getNotifications()
  // ────────────────────────────────────────────
  Future<Map<String, dynamic>> getUnreadNotifications() async {
    try {
      final response = await service.getUnreadNotifications();
      final data = response.data;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final notifications = _parseList(data);
        return {'success': true, 'notifications': notifications};
      }

      return {
        'success': false,
        'message': _extractMessage(data, 'Failed to load unread notifications'),
        'errors': data is Map ? data['errors'] : null,
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  // ────────────────────────────────────────────
  // 4) GET /api/notifications/unreadcount
  //    Response key: "number of unread notification"
  // ────────────────────────────────────────────
  Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      final response = await service.getUnreadCount();
      final data = response.data;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final map = _asMap(data) ?? {};
        final result = UnreadCountResult.fromJson(map);
        return {'success': true, 'count': result.count};
      }

      return {
        'success': false,
        'message': _extractMessage(data, 'Failed to load unread count'),
        'errors': data is Map ? data['errors'] : null,
        'count': 0,
      };
    } on DioException catch (e) {
      final err = _errorPayload(e);
      err['count'] = 0;
      return err;
    }
  }

  // ────────────────────────────────────────────
  // 5) PATCH /api/notifications/{id}/markAsRead
  // ────────────────────────────────────────────
  Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    try {
      final response = await service.markAsRead(notificationId);
      final data = response.data;

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Resource returns single object (possibly wrapped in "data")
        Map<String, dynamic>? raw;
        if (data is Map) {
          raw = _asMap(data['data']) ?? _asMap(data);
        }

        return {
          'success': true,
          'message': 'Notification marked as read.',
          'notification': raw != null
              ? AppNotificationModel.fromJson(raw)
              : null,
        };
      }

      return {
        'success': false,
        'message': _extractMessage(data, 'Failed to mark notification as read'),
        'errors': data is Map ? data['errors'] : null,
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  // ────────────────────────────────────────────
  // 6) PATCH /api/notifications/markAllAsRead
  // ────────────────────────────────────────────
  Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final response = await service.markAllAsRead();
      final data = response.data;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final notifications = _parseList(data);
        return {
          'success': true,
          'message': 'All notifications marked as read.',
          'notifications': notifications,
        };
      }

      return {
        'success': false,
        'message': _extractMessage(data, 'Failed to mark all as read'),
        'errors': data is Map ? data['errors'] : null,
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  // ────────────────────────────────────────────
  // 7) DELETE /api/notifications/{id}/delete
  //    Success body: { "Notification deleted" }  (or message string)
  // ────────────────────────────────────────────
  Future<Map<String, dynamic>> deleteNotification(String notificationId) async {
    try {
      final response = await service.deleteNotification(notificationId);
      final data = response.data;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Notification deleted',
          'raw': data,
        };
      }

      return {
        'success': false,
        'message': _extractMessage(data, 'Failed to delete notification'),
        'errors': data is Map ? data['errors'] : null,
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }
}
