import 'package:dio/dio.dart';
import 'package:fluent/data/models/course_model.dart';
import 'package:fluent/data/models/lesson_model.dart';
import 'package:fluent/data/services/lesson_service.dart';

class LessonRepository {
  final LessonService lessonService;
  LessonRepository(this.lessonService);

  // ────────────────────────────────────────────
  // Shared helpers (same conventions as QuestionRepository)
  // ────────────────────────────────────────────

  // Laravel wraps a single JsonResource in a top-level "data" key by default.
  Map<String, dynamic> _unwrapResource(Map<String, dynamic> raw) {
    final inner = raw['data'];
    if (inner is Map<String, dynamic> && (inner['id'] != null)) {
      return inner;
    }
    return raw;
  }

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

  // ────────────────────────────────────────────
  // 1) GET /getTeacherCourses
  //    CourseResource::collection() -> wrapped in { "data": [...] }
  // ────────────────────────────────────────────
  Future<Map<String, dynamic>> getTeacherCourses() async {
    try {
      final response = await lessonService.getTeacherCourses();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          final courses = (data['data'] as List)
              .whereType<Map>()
              .map((e) => CourseModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          return {'success': true, 'data': courses};
        }
      }
      final err = response.data;
      return {
        'success': false,
        'message': _extractMessage(err, 'Failed to load your courses'),
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  // ────────────────────────────────────────────
  // 2) GET /lessons/{course}
  //    LessonResource::collection() over a paginator -> top-level
  //    { "data": [...], "links": {...}, "meta": {...} }
  // ────────────────────────────────────────────
  Future<Map<String, dynamic>> getLessonsByCourse(
    int courseId, {
    int page = 1,
  }) async {
    try {
      final response = await lessonService.getLessons(courseId, page: page);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          final lessons = (data['data'] as List)
              .whereType<Map>()
              .map((e) => LessonModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();

          final meta = data['meta'] is Map<String, dynamic>
              ? data['meta'] as Map<String, dynamic>
              : data;

          return {
            'success': true,
            'data': PaginatedLessons(
              lessons: lessons,
              currentPage: meta['current_page'] is int
                  ? meta['current_page']
                  : 1,
              lastPage: meta['last_page'] is int ? meta['last_page'] : 1,
              perPage: meta['per_page'] is int ? meta['per_page'] : 10,
              total: meta['total'] is int ? meta['total'] : lessons.length,
            ),
          };
        }
      }
      final err = response.data;
      return {
        'success': false,
        'message': _extractMessage(err, 'Failed to load lessons'),
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  // ────────────────────────────────────────────
  // 3) POST /lessons/{course}  (store)
  // ────────────────────────────────────────────
  Future<Map<String, dynamic>> createLesson(
    int courseId,
    FormData formData,
  ) async {
    try {
      final response = await lessonService.createLesson(courseId, formData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return {
            'success': true,
            'data': LessonModel.fromJson(_unwrapResource(data)),
          };
        }
      }
      final err = response.data;
      return {
        'success': false,
        'message': _extractMessage(err, 'Failed to create lesson'),
        'errors': err is Map ? err['errors'] : null,
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  // ────────────────────────────────────────────
  // 4) POST /lessons/{lesson}/update
  // ────────────────────────────────────────────
  Future<Map<String, dynamic>> updateLesson(
    int lessonId,
    FormData formData,
  ) async {
    try {
      final response = await lessonService.updateLesson(lessonId, formData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return {
            'success': true,
            'data': LessonModel.fromJson(_unwrapResource(data)),
          };
        }
      }
      final err = response.data;
      return {
        'success': false,
        'message': _extractMessage(err, 'Failed to update lesson'),
        'errors': err is Map ? err['errors'] : null,
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  // ✅ إضافة دالة الحذف في الـ Repository
  Future<Map<String, dynamic>> deleteLesson(int lessonId) async {
    try {
      final response = await lessonService.deleteLesson(lessonId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return {
          'success': true,
          'message': data['message'] ?? 'Lesson deleted successfully',
        };
      }
      final err = response.data;
      return {
        'success': false,
        'message': _extractMessage(err, 'Failed to delete lesson'),
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }
}

class PaginatedLessons {
  final List<LessonModel> lessons;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginatedLessons({
    required this.lessons,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}
