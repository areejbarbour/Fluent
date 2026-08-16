import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/cubit/safe_cubit.dart';
import 'package:fluent/data/models/notification_model.dart';
import 'package:fluent/data/repository/notification_repository.dart';
import 'notification_state.dart';

class NotificationCubit extends SafeCubit<NotificationState> {
  final NotificationRepository repository;

  NotificationCubit(this.repository) : super(const NotificationState());

  Future<void> loadNotifications() async {
    emit(state.copyWith(loading: true, error: null));
    final result = await repository.getNotifications();

    if (result['success'] == true) {
      final list =
          (result['notifications'] as List<AppNotificationModel>?) ?? [];
      final unread = list.where((n) => !n.isRead).length;
      emit(
        state.copyWith(
          loading: false,
          notifications: list,
          unreadCount: unread,
        ),
      );
    } else {
      emit(
        state.copyWith(
          loading: false,
          error:
              result['message']?.toString() ?? 'Failed to load notifications',
        ),
      );
    }
  }

  Future<void> loadUnreadCount() async {
    final result = await repository.getUnreadCount();
    if (result['success'] == true) {
      emit(state.copyWith(unreadCount: result['count'] as int? ?? 0));
    }
  }

  Future<void> registerFirebaseToken({
    required String token,
    String? deviceType,
    String? deviceName,
  }) async {
    await repository.registerFirebaseToken(
      token: token,
      deviceType: deviceType,
      deviceName: deviceName,
    );
  }

  Future<void> markAsRead(String id) async {
    if (id.trim().isEmpty) return;

    final optimistic = state.notifications.map((n) {
      if (n.id == id && !n.isRead) {
        return n.copyWith(
          isRead: true,
          readAt: DateTime.now().toIso8601String(),
        );
      }
      return n;
    }).toList();
    final optimisticCount = optimistic.where((n) => !n.isRead).length;

    emit(
      state.copyWith(
        notifications: optimistic,
        unreadCount: optimisticCount,
        actionLoading: true,
        error: null,
        actionSuccess: false,
      ),
    );

    final result = await repository.markAsRead(id);

    if (result['success'] == true) {
      emit(
        state.copyWith(
          actionLoading: false,
          actionSuccess: true,
          message: result['message']?.toString() ?? 'Marked as read',
        ),
      );
    } else {
      await loadNotifications();
      emit(
        state.copyWith(
          actionLoading: false,
          actionSuccess: false,
          error: result['message']?.toString() ?? 'Failed to mark as read',
        ),
      );
    }
  }

  Future<void> markAllAsRead() async {
    final optimistic = state.notifications
        .map(
          (n) => n.copyWith(
            isRead: true,
            readAt: DateTime.now().toIso8601String(),
          ),
        )
        .toList();

    emit(
      state.copyWith(
        notifications: optimistic,
        unreadCount: 0,
        actionLoading: true,
        error: null,
        actionSuccess: false,
      ),
    );

    final result = await repository.markAllAsRead();

    if (result['success'] == true) {
      emit(
        state.copyWith(
          actionLoading: false,
          actionSuccess: true,
          message: result['message']?.toString() ?? 'All marked as read',
        ),
      );
    } else {
      await loadNotifications();
      emit(
        state.copyWith(
          actionLoading: false,
          actionSuccess: false,
          error: result['message']?.toString() ?? 'Failed to mark all',
        ),
      );
    }
  }

  Future<void> deleteNotification(String id) async {
    if (id.trim().isEmpty) return;

    final removed = state.notifications.where((n) => n.id == id).toList();
    final optimistic = state.notifications.where((n) => n.id != id).toList();
    var newCount = state.unreadCount;
    if (removed.isNotEmpty && !removed.first.isRead) {
      newCount = (newCount - 1).clamp(0, 999999);
    }

    emit(
      state.copyWith(
        notifications: optimistic,
        unreadCount: newCount,
        actionLoading: true,
        error: null,
        actionSuccess: false,
      ),
    );

    final result = await repository.deleteNotification(id);

    if (result['success'] == true) {
      emit(
        state.copyWith(
          actionLoading: false,
          actionSuccess: true,
          message: result['message']?.toString() ?? 'Deleted',
        ),
      );
    } else {
      await loadNotifications();
      emit(
        state.copyWith(
          actionLoading: false,
          actionSuccess: false,
          error: result['message']?.toString() ?? 'Failed to delete',
        ),
      );
    }
  }

  Future<void> deleteMultiple(List<String> ids) async {
    final clean = ids.where((id) => id.trim().isNotEmpty).toSet().toList();
    if (clean.isEmpty) return;

    final removedUnread = state.notifications
        .where((n) => clean.contains(n.id) && !n.isRead)
        .length;
    final optimistic = state.notifications
        .where((n) => !clean.contains(n.id))
        .toList();
    final newCount = (state.unreadCount - removedUnread).clamp(0, 999999);

    emit(
      state.copyWith(
        notifications: optimistic,
        unreadCount: newCount,
        actionLoading: true,
        error: null,
        actionSuccess: false,
      ),
    );

    var failed = 0;
    for (final id in clean) {
      final result = await repository.deleteNotification(id);
      if (result['success'] != true) failed++;
    }

    if (failed == 0) {
      emit(
        state.copyWith(
          actionLoading: false,
          actionSuccess: true,
          message: clean.length == 1
              ? 'Notification deleted'
              : '${clean.length} notifications deleted',
        ),
      );
    } else {
      await loadNotifications();
      emit(
        state.copyWith(
          actionLoading: false,
          actionSuccess: false,
          error: failed == clean.length
              ? 'Failed to delete notifications'
              : 'Deleted with $failed error(s)',
        ),
      );
    }
  }

  void clearActionResult() {
    emit(state.copyWith(actionSuccess: false, error: null, message: null));
  }

  void clearSession() {
    emit(const NotificationState());
  }

  Future<void> loadUnreadOnly() async {
    emit(state.copyWith(loading: true, error: null));
    final result = await repository.getUnreadNotifications();

    if (result['success'] == true) {
      final list =
          (result['notifications'] as List<AppNotificationModel>?) ?? [];
      emit(
        state.copyWith(
          loading: false,
          notifications: list,
          unreadCount: list.length,
        ),
      );
    } else {
      await loadNotifications();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([loadUnreadCount(), loadNotifications()]);
  }
}
