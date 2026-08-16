import 'package:dio/dio.dart';
import 'package:fluent/data/models/content_review_model.dart';
import 'package:fluent/data/models/lesson_model.dart';
import 'package:fluent/data/models/test_model.dart';
import 'package:fluent/data/services/content_review_service.dart';

class ContentReviewRepository {
  final ContentReviewService service;
  ContentReviewRepository(this.service);

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

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  Future<Map<String, dynamic>> submitLesson(int lessonId) async {
    try {
      final response = await service.submitLesson(lessonId);
      final data = response.data;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final map = _asMap(data) ?? {};
        final lessonRaw = _asMap(map['lesson']);
        final testRaw = _asMap(map['test']);

        return {
          'success': true,
          'message': 'Lesson submitted for review successfully.',
          'lesson': lessonRaw != null ? LessonModel.fromJson(lessonRaw) : null,
          'test': testRaw != null ? TestModel.fromJson(testRaw) : null,
          'raw': map,
        };
      }

      return {
        'success': false,
        'message': _extractMessage(data, 'Failed to submit lesson for review'),
        'errors': data is Map ? data['errors'] : null,
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  Future<Map<String, dynamic>> resubmitLesson(int lessonId) async {
    try {
      final response = await service.resubmitLesson(lessonId);
      final data = response.data;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final map = _asMap(data) ?? {};
        final lessonRaw = _asMap(map['lesson']);
        final reviewRaw = _asMap(map['review']);

        return {
          'success': true,
          'message': 'Lesson resubmitted successfully.',
          'lesson': lessonRaw != null ? LessonModel.fromJson(lessonRaw) : null,
          'review': reviewRaw != null
              ? ContentReviewSession.fromJson(reviewRaw)
              : null,
          'raw': map,
        };
      }

      return {
        'success': false,
        'message': _extractMessage(
          data,
          'Failed to resubmit lesson for review',
        ),
        'errors': data is Map ? data['errors'] : null,
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  Future<Map<String, dynamic>> submitTest(int testId) async {
    try {
      final response = await service.submitTest(testId);
      final data = response.data;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final map = _asMap(data) ?? {};
        final testRaw = _asMap(map['test']);

        return {
          'success': true,
          'message': 'Test submitted for review successfully.',
          'test': testRaw != null ? TestModel.fromJson(testRaw) : null,
          'raw': map,
        };
      }

      return {
        'success': false,
        'message': _extractMessage(data, 'Failed to submit test for review'),
        'errors': data is Map ? data['errors'] : null,
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  Future<Map<String, dynamic>> resubmitTest(int testId) async {
    try {
      final response = await service.resubmitTest(testId);
      final data = response.data;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final map = _asMap(data) ?? {};
        final testRaw = _asMap(map['test']);
        final reviewRaw = _asMap(map['review']);

        return {
          'success': true,
          'message': 'Test resubmitted successfully.',
          'test': testRaw != null ? TestModel.fromJson(testRaw) : null,
          'review': reviewRaw != null
              ? ContentReviewSession.fromJson(reviewRaw)
              : null,
          'raw': map,
        };
      }

      return {
        'success': false,
        'message': _extractMessage(data, 'Failed to resubmit test for review'),
        'errors': data is Map ? data['errors'] : null,
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  Future<Map<String, dynamic>> lessonReviewHistory(int lessonId) async {
    try {
      final response = await service.lessonReviewHistory(lessonId);
      final data = response.data;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final map = _asMap(data) ?? {};
        final list = map['history'];
        final history = <ReviewHistoryItem>[];

        if (list is List) {
          for (final item in list) {
            if (item is Map) {
              history.add(
                ReviewHistoryItem.fromJson(Map<String, dynamic>.from(item)),
              );
            }
          }
        }

        return {'success': true, 'history': history};
      }

      return {
        'success': false,
        'message': _extractMessage(
          data,
          'Failed to load lesson review history',
        ),
        'errors': data is Map ? data['errors'] : null,
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  Future<Map<String, dynamic>> testReviewHistory(int testId) async {
    try {
      final response = await service.testReviewHistory(testId);
      final data = response.data;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final map = _asMap(data) ?? {};
        final list = map['history'];
        final history = <ReviewHistoryItem>[];

        if (list is List) {
          for (final item in list) {
            if (item is Map) {
              history.add(
                ReviewHistoryItem.fromJson(Map<String, dynamic>.from(item)),
              );
            }
          }
        }

        return {'success': true, 'history': history};
      }

      return {
        'success': false,
        'message': _extractMessage(data, 'Failed to load test review history'),
        'errors': data is Map ? data['errors'] : null,
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }
}
