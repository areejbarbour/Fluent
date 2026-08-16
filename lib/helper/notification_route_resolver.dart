import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fluent/constants/strings.dart';
import 'package:fluent/data/models/notification_model.dart';

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
    final reviewableType = _string(data, [
      'reviewable_type',
      'content_type',
      'target_type',
    ]).toLowerCase();
    final reviewableId = _idFrom(data, [
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
      case AppNotificationModel.typeLessonOpened:
        final lessonId = _idFrom(data, ['lesson_id', 'lessonId', 'id']);
        if (lessonId != null) {
          return _lessonTarget(lessonId, isTeacher, fallbackTitle);
        }
        break;

      // Backend payload: { "topic_id": <int> }
      // Plain int (unlike most other types), but there's no dedicated
      // "topic detail" screen registered in app_router.dart today, so we
      // deliberately fall through to the safe default below rather than
      // guessing a destination.
      case AppNotificationModel.typeTopicPublished:
        break;

      // Backend payload: { "course_id": <full Course model JSON> }
      // Only ever sent to a teacher (AdminCourseService, on assignment).
      // teacherCourseDetailRoute requires a full CourseModel instance as
      // its route argument (see app_router.dart), which we can't safely
      // reconstruct from a push/JSON payload — so we open the teacher's
      // course library instead, same as before.
      case AppNotificationModel.typeCourseAssigned:
        return _RouteTarget(teacherCoursesRoute, null);

      // Backend payload: { "level": <full Level model JSON> }
      // Sent to the student after a successful payment (StripeWebhookService).
      case AppNotificationModel.typeLevelOpened:
        final levelId = _idFrom(data, ['level', 'level_id', 'levelId']);
        if (levelId != null) {
          return _RouteTarget(levelCoursesRoute, {'levelId': levelId});
        }
        return _RouteTarget(studentHomeRoute, null);

      case AppNotificationModel.typePodcastCreated:
        return _RouteTarget(podcastsRoute, null);

      // Backend payload: { "level_exception": <full LevelException model JSON> }
      case AppNotificationModel.typeLevelExceptionApproved:
        final exceptionId = _idFrom(data, [
          'level_exception',
          'level_exception_id',
          'levelExceptionId',
          'id',
        ]);
        if (exceptionId != null) {
          return _RouteTarget(levelExceptionDetailsRoute, {'id': exceptionId});
        }
        return _RouteTarget(levelExceptionsRoute, null);

      // Backend payload: { "level_exception_id": <full LevelException model JSON> }
      // NOTE: despite the key's "_id" suffix, the backend actually puts the
      // full model there (AdminLevelExceptionService::reject) — _idFrom()
      // handles both shapes so this works whether or not that ever changes.
      case AppNotificationModel.typeLevelExceptionReject:
        final rejectId = _idFrom(data, [
          'level_exception_id',
          'level_exception',
          'levelExceptionId',
          'id',
        ]);
        if (rejectId != null) {
          return _RouteTarget(levelExceptionDetailsRoute, {'id': rejectId});
        }
        return _RouteTarget(levelExceptionsRoute, null);

      // Backend payload: { "level_exception_id": <int>, "level_id": <int>, "user_id": <int> }
      // Dispatched to super-admins only (StudentLevelExceptionService) — this
      // teacher/student app is unlikely to ever receive one, but the shape
      // is a plain int here (unlike the two cases above) so we still route
      // it correctly if it ever does show up.
      case AppNotificationModel.typeLevelException:
        final requestId = _idFrom(data, ['level_exception_id', 'id']);
        if (requestId != null) {
          return _RouteTarget(levelExceptionDetailsRoute, {'id': requestId});
        }
        return _RouteTarget(levelExceptionsRoute, null);

      // Backend payload: { "test_id": <int>, "removed_question_ids": <int[]> }
      // Teacher-only (Test content-review workflow).
      case AppNotificationModel.typeContentDependencyChange:
        final testId = _idFrom(data, ['test_id', 'testId']);
        if (testId != null) {
          return _RouteTarget(testDetailViewRoute, {'testId': testId});
        }
        break;

      // Backend payload: { "lesson_id": <int>, "course_id": <int> }
      // Sent to the reviewer teacher AFTER the lesson was deleted — the
      // lesson no longer exists, so there is nothing to open a detail
      // screen for. Falls through to the notifications list on purpose.
      case AppNotificationModel.typeDeleteLesson:
        break;
    }

    // Unknown type, or a known type without enough data to build a specific
    // destination → safest bet is the notifications list, where the user
    // can still see full context.
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

  /// Extracts an int id from `data[key]` for each key in order, where the
  /// value may be:
  ///  • a plain int/num
  ///  • a numeric string
  ///  • a full serialized model object, e.g. `{"id": 5, "name_en": "...", ...}`
  ///    (several backend dispatch sites pass the Eloquent model itself
  ///    instead of `->id` — see notification_model.dart's type doc comments)
  static int? _idFrom(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final raw = data[key];
      if (raw == null) continue;

      if (raw is int) return raw;
      if (raw is num) return raw.toInt();

      if (raw is Map) {
        final nested = raw['id'];
        if (nested is int) return nested;
        if (nested is num) return nested.toInt();
        if (nested != null) {
          final parsed = int.tryParse(nested.toString());
          if (parsed != null) return parsed;
        }
        continue; // don't fall through to raw.toString() on a whole Map
      }

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
