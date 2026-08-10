import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fluent/constants/strings.dart';
import 'package:fluent/data/models/notification_model.dart';

/// Decides which screen a notification should open, then pushes it.
///
/// One resolver is shared by every place a notification can be tapped:
///  • the system-tray notification (app in background / killed)
///  • a foreground FCM message shown via [LocalNotificationsService]
///  • a tile inside [NotificationsScreen]
///
/// so all three behave exactly the same way.
///
/// Routing is driven by the notification's `type` (see
/// [AppNotificationModel]'s `typeXxx` constants) plus its `data` payload.
/// The expected `data` keys per type are documented next to each branch
/// below — align them with whatever the backend actually sends. Whenever
/// the payload doesn't carry enough information to build a specific
/// destination, the resolver falls back to the notifications list itself
/// rather than doing nothing.
class NotificationRouteResolver {
  NotificationRouteResolver._();

  static Future<void> open(
    BuildContext context, {
    required String type,
    Map<String, dynamic> data = const {},
    String? fallbackTitle,
  }) async {
    final isTeacher = await _isTeacher();
    final target = _resolve(
      type: type,
      data: data,
      isTeacher: isTeacher,
      fallbackTitle: fallbackTitle,
    );

    if (!context.mounted) return;

    try {
      Navigator.of(
        context,
      ).pushNamed(target.route, arguments: target.arguments);
    } catch (e) {
      debugPrint('⚠️ [NotificationRouteResolver] navigation failed: $e');
    }
  }

  static Future<bool> _isTeacher() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_role') == 'teacher';
    } catch (_) {
      return false;
    }
  }

  static _RouteTarget _resolve({
    required String type,
    required Map<String, dynamic> data,
    required bool isTeacher,
    String? fallbackTitle,
  }) {
    // Laravel-style polymorphic payload used by content-review
    // notifications: { reviewable_type: "lesson|course|test|word|question",
    // reviewable_id: 12 }. These notifications are teacher-only (they come
    // from the teacher content-review workflow).
    final reviewableType = _string(data, [
      'reviewable_type',
      'content_type',
      'target_type',
    ]).toLowerCase();
    final reviewableId = _int(data, [
      'reviewable_id',
      'content_id',
      'target_id',
    ]);

    final isContentReviewType =
        type == AppNotificationModel.typeContentApproved ||
        type == AppNotificationModel.typeContentChangesRequested ||
        type == AppNotificationModel.typeContentPublished;

    if (isContentReviewType && reviewableId != null) {
      switch (reviewableType) {
        case 'lesson':
          return _lessonTarget(reviewableId, true, fallbackTitle);
        case 'test':
          return _RouteTarget(testDetailViewRoute, {'testId': reviewableId});
        case 'course':
          return _RouteTarget(teacherCoursesRoute, null);
        case 'question':
          return _RouteTarget(questionsListRoute, null);
        default:
          // word, or an unrecognised content type — no dedicated
          // standalone screen to deep-link into yet.
          break;
      }
    }

    switch (type) {
      // data: { lesson_id / lessonId, lesson_title? }
      case AppNotificationModel.typeLessonOpened:
      case AppNotificationModel.typeTopicPublished:
        final lessonId = _int(data, ['lesson_id', 'lessonId', 'id']);
        if (lessonId != null) {
          return _lessonTarget(lessonId, isTeacher, fallbackTitle);
        }
        break;

      // data: { course_id / courseId, level_id / levelId? }
      case AppNotificationModel.typeCourseOpened:
        if (isTeacher) {
          // Teacher course detail needs the full CourseModel, which a
          // push payload can't carry — open the courses library instead.
          return _RouteTarget(teacherCoursesRoute, null);
        }
        final levelId = _int(data, ['level_id', 'levelId']);
        if (levelId != null) {
          return _RouteTarget(levelCoursesRoute, {'levelId': levelId});
        }
        return _RouteTarget(studentHomeRoute, null);

      case AppNotificationModel.typePodcastCreated:
        return _RouteTarget(podcastsRoute, null);

      // data: { level_exception_id / id }
      case AppNotificationModel.typeLevelExceptionApproved:
        final exceptionId = _int(data, [
          'level_exception_id',
          'levelExceptionId',
          'id',
        ]);
        if (exceptionId != null) {
          return _RouteTarget(levelExceptionDetailsRoute, {
            'id': exceptionId,
          });
        }
        return _RouteTarget(levelExceptionsRoute, null);
    }

    // Unknown type or missing ids → safest bet is the notifications list,
    // where the user can still see full context.
    return _RouteTarget(notificationsRoute, null);
  }

  static _RouteTarget _lessonTarget(
    int lessonId,
    bool isTeacher,
    String? title,
  ) {
    final lessonTitle = (title == null || title.trim().isEmpty)
        ? 'Lesson'
        : title;
    if (isTeacher) {
      return _RouteTarget(lessonDetailRoute, {
        'lessonId': lessonId,
        'lessonTitle': lessonTitle,
      });
    }
    return _RouteTarget(lessonStudentDetailRoute, {
      'lessonId': lessonId,
      'lessonTitle': lessonTitle,
    });
  }

  static int? _int(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final raw = data[key];
      if (raw == null) continue;
      if (raw is int) return raw;
      final parsed = int.tryParse(raw.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  static String _string(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final raw = data[key];
      if (raw == null) continue;
      final s = raw.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }
}

class _RouteTarget {
  final String route;
  final Map<String, dynamic>? arguments;

  const _RouteTarget(this.route, this.arguments);
}
